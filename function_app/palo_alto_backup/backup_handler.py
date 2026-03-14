"""
Palo Alto Config Backup — Azure Function
Timer trigger: daily at 02:30 UTC (30 min after AWS Lambda)

Backs up running configs from Azure prod Panorama and firewall(s) via
PAN-OS XML API. Archives to Azure Blob Storage, commits latest to GitHub,
alerts via SES SMTP on change or failure.

App Settings (set via Terraform):
  DEVICES                  - JSON list of devices
  BACKUP_STORAGE_CONN_STR  - Connection string for backup storage account
  BACKUP_CONTAINER         - Blob container name (default: firewall-configs)
  KEYVAULT_URI             - Key Vault URI for device credentials + GitHub PAT
  SES_SMTP_SECRET_NAME     - Key Vault secret name for SES SMTP credentials
  GITHUB_SECRET_NAME       - Key Vault secret name for GitHub PAT + repo details
  SES_SENDER               - Verified SES sender email
  SES_RECIPIENT            - Alert recipient email
  SES_SMTP_HOST            - SES SMTP host (default: email-smtp.us-west-2.amazonaws.com)
"""

import azure.functions as func
import json
import os
import hashlib
import base64
import ssl
import datetime
import logging
import smtplib
import time
import email.mime.text
import email.mime.multipart
import urllib.request
import urllib.parse
import urllib.error
import xml.etree.ElementTree as ET

from azure.identity import ManagedIdentityCredential
from azure.keyvault.secrets import SecretClient
from azure.storage.blob import BlobServiceClient

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Key Vault
# ---------------------------------------------------------------------------

def _kv_client() -> SecretClient:
    credential = ManagedIdentityCredential()
    return SecretClient(vault_url=os.environ["KEYVAULT_URI"], credential=credential)


def get_secret(kv: SecretClient, secret_name: str) -> dict:
    value = kv.get_secret(secret_name).value
    return json.loads(value)


# ---------------------------------------------------------------------------
# Blob Storage
# ---------------------------------------------------------------------------

def _blob_client() -> BlobServiceClient:
    return BlobServiceClient.from_connection_string(
        os.environ["BACKUP_STORAGE_CONN_STR"]
    )


def get_blob_text(blob_svc: BlobServiceClient, container: str, blob_name: str) -> str | None:
    try:
        client = blob_svc.get_blob_client(container=container, blob=blob_name)
        return client.download_blob().readall().decode("utf-8")
    except Exception:
        return None


def put_blob_text(blob_svc: BlobServiceClient, container: str, blob_name: str, content: str) -> None:
    client = blob_svc.get_blob_client(container=container, blob=blob_name)
    client.upload_blob(content.encode("utf-8"), overwrite=True)


# ---------------------------------------------------------------------------
# PAN-OS XML API (identical to Lambda version)
# ---------------------------------------------------------------------------

def _ssl_ctx() -> ssl.SSLContext:
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    return ctx


def export_panos_config(host: str, api_key: str,
                        max_attempts: int = 3, retry_delays: tuple = (5, 15)) -> str:
    """Pull full running config from a PAN-OS device.

    Retries up to max_attempts times on any error (transient network issues,
    timeouts, etc.) with exponential-ish backoff between attempts.
    """
    params = urllib.parse.urlencode({
        "type": "export",
        "category": "configuration",
        "key": api_key,
    })
    url = f"https://{host}/api/?{params}"
    last_exc: Exception = RuntimeError("No attempts made")

    for attempt in range(1, max_attempts + 1):
        try:
            logger.info(f"export_panos_config: {host} [attempt {attempt}/{max_attempts}]")
            with urllib.request.urlopen(
                urllib.request.Request(url),
                context=_ssl_ctx(),
                timeout=30,
            ) as resp:
                content = resp.read().decode("utf-8")

            root = ET.fromstring(content)
            # Config export returns raw <config> XML, not a <response> wrapper.
            # Only treat as error if we got a <response status="error|..."> back.
            if root.tag == "response" and root.get("status") != "success":
                msg = root.findtext(".//msg") or content[:200]
                raise RuntimeError(f"PAN-OS API error: {msg}")
            return content

        except Exception as exc:
            last_exc = exc
            if attempt < max_attempts:
                delay = retry_delays[attempt - 1] if attempt - 1 < len(retry_delays) else retry_delays[-1]
                logger.warning(
                    f"export_panos_config: {host} attempt {attempt}/{max_attempts} failed "
                    f"({exc!r}) — retrying in {delay}s"
                )
                time.sleep(delay)
            else:
                logger.error(
                    f"export_panos_config: {host} failed after {max_attempts} attempts: {exc!r}"
                )

    raise last_exc


# ---------------------------------------------------------------------------
# Change detection
# ---------------------------------------------------------------------------

def compute_hash(content: str) -> str:
    return hashlib.sha256(content.encode("utf-8")).hexdigest()


# ---------------------------------------------------------------------------
# GitHub API (identical to Lambda version)
# ---------------------------------------------------------------------------

def _gh_headers(token: str) -> dict:
    return {
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github.v3+json",
        "Content-Type": "application/json",
        "User-Agent": "palo-alto-backup-azfunc/1.0",
    }


def github_get_file_sha(token: str, repo: str, path: str, branch: str) -> str | None:
    url = f"https://api.github.com/repos/{repo}/contents/{path}?ref={branch}"
    try:
        with urllib.request.urlopen(
            urllib.request.Request(url, headers=_gh_headers(token)), timeout=30
        ) as resp:
            return json.loads(resp.read().decode("utf-8")).get("sha")
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return None
        raise


def github_commit_file(
    token: str, repo: str, path: str, content: str,
    message: str, branch: str, current_sha: str | None = None,
) -> None:
    url = f"https://api.github.com/repos/{repo}/contents/{path}"
    payload = {
        "message": message,
        "content": base64.b64encode(content.encode("utf-8")).decode("utf-8"),
        "branch": branch,
    }
    if current_sha:
        payload["sha"] = current_sha
    req = urllib.request.Request(
        url, data=json.dumps(payload).encode("utf-8"),
        method="PUT", headers=_gh_headers(token),
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        result = json.loads(resp.read().decode("utf-8"))
        logger.info(f"GitHub commit: {result.get('commit', {}).get('sha', '')[:8]}")


# ---------------------------------------------------------------------------
# SES SMTP (stdlib smtplib — no AWS SDK needed)
# ---------------------------------------------------------------------------

def send_ses_smtp(
    subject: str, body: str, sender: str, recipient: str,
    smtp_host: str, smtp_user: str, smtp_pass: str,
) -> None:
    msg = email.mime.multipart.MIMEMultipart("alternative")
    msg["Subject"] = subject
    msg["From"]    = sender
    msg["To"]      = recipient
    msg.attach(email.mime.text.MIMEText(body, "plain"))

    with smtplib.SMTP(smtp_host, 587, timeout=30) as server:
        server.ehlo()
        server.starttls()
        server.login(smtp_user, smtp_pass)
        server.sendmail(sender, [recipient], msg.as_string())


# ---------------------------------------------------------------------------
# Per-device backup logic
# ---------------------------------------------------------------------------

def backup_device(
    device: dict, kv: SecretClient, blob_svc: BlobServiceClient,
    container: str, github_token: str, github_repo: str,
    github_branch: str, timestamp: str,
) -> dict:
    name = device["name"]
    try:
        creds   = get_secret(kv, device["secret_name"])
        host    = creds["ip"]
        api_key = creds["api_key"]

        logger.info(f"Exporting config from {name} ({host})")
        config_xml = export_panos_config(host, api_key)

        current_hash  = compute_hash(config_xml)
        previous_hash = get_blob_text(blob_svc, container, f"hashes/{name}.sha256")
        changed = current_hash != (previous_hash or "")

        # Archive timestamped copy
        put_blob_text(blob_svc, container, f"archive/{name}/{timestamp}.xml", config_xml)

        # Write latest copy for audit function to read
        put_blob_text(blob_svc, container, f"{name}/running-config.xml", config_xml)

        # Update hash
        put_blob_text(blob_svc, container, f"hashes/{name}.sha256", current_hash)

        # Commit latest to GitHub
        github_path = f"firewall-configs/{name}/running-config.xml"
        current_sha = github_get_file_sha(github_token, github_repo, github_path, github_branch)
        commit_msg = (
            f"feat(firewall): {name} config changed [{timestamp}]"
            if changed else
            f"chore(firewall): {name} config backup [{timestamp}]"
        )
        github_commit_file(
            token=github_token, repo=github_repo, path=github_path,
            content=config_xml, message=commit_msg, branch=github_branch,
            current_sha=current_sha,
        )

        status = "CHANGED" if changed else "UNCHANGED"
        logger.info(f"{name}: {status}")
        # config_xml is returned so callers can pass it directly to run_audit
        # without a second blob read (FIX 4 — avoid separate API call for audit).
        return {"name": name, "status": status, "error": None,
                "config_xml": config_xml, "backup_timestamp": timestamp}

    except Exception as e:
        logger.error(f"Backup failed for {name}: {e}", exc_info=True)
        return {"name": name, "status": "FAILED", "error": str(e),
                "config_xml": None, "backup_timestamp": timestamp}


# ---------------------------------------------------------------------------
# Timer Trigger — daily 02:30 UTC
# ---------------------------------------------------------------------------

def run_backup() -> list[dict]:
    """Core backup logic. Returns list of per-device result dicts.

    Sends an alert email if any device changed or failed.
    Raises RuntimeError if any device failed (so the timer trigger marks as failed).
    """
    devices       = json.loads(os.environ["DEVICES"])
    container     = os.environ.get("BACKUP_CONTAINER", "firewall-configs")
    ses_sender    = os.environ["SES_SENDER"]
    ses_recipient = os.environ["SES_RECIPIENT"]
    smtp_host       = os.environ.get("SES_SMTP_HOST", "email-smtp.us-west-2.amazonaws.com")
    deployment_name = os.environ.get("DEPLOYMENT_NAME", "Azure")

    timestamp = datetime.datetime.utcnow().strftime("%Y%m%d_%H%M%S")
    kv        = _kv_client()
    blob_svc  = _blob_client()

    github_creds  = get_secret(kv, os.environ["GITHUB_SECRET_NAME"])
    github_token  = github_creds["token"]
    github_repo   = github_creds["repo"]
    github_branch = github_creds.get("branch", "main")

    results = [
        backup_device(
            device=d, kv=kv, blob_svc=blob_svc, container=container,
            github_token=github_token, github_repo=github_repo,
            github_branch=github_branch, timestamp=timestamp,
        )
        for d in devices
    ]

    changed = [r["name"] for r in results if r["status"] == "CHANGED"]
    failed  = [r for r in results if r["status"] == "FAILED"]

    # Always send a status email so every backup run is confirmed
    subject_parts = []
    if changed:
        subject_parts.append(f"Config changed: {', '.join(changed)}")
    if failed:
        subject_parts.append(f"FAILED: {len(failed)} device(s)")
    if not subject_parts:
        subject_parts.append("All devices unchanged")

    lines = [f"Palo Alto Config Backup Report ({deployment_name})", "=" * 50, f"Run: {timestamp}", ""]
    for r in results:
        icon = {"CHANGED": "⚠", "UNCHANGED": "✓", "FAILED": "✗"}.get(r["status"], "?")
        lines.append(f"  {icon}  {r['name']}: {r['status']}")
        if r["error"]:
            lines.append(f"      Error: {r['error']}")
    if failed:
        lines += ["", "ACTION REQUIRED: Manual backup recommended for failed devices."]

    try:
        smtp_creds = get_secret(kv, os.environ["SES_SMTP_SECRET_NAME"])
        send_ses_smtp(
            subject=f"[Palo Alto Backup {deployment_name}] {' | '.join(subject_parts)}",
            body="\n".join(lines),
            sender=ses_sender,
            recipient=ses_recipient,
            smtp_host=smtp_host,
            smtp_user=smtp_creds["username"],
            smtp_pass=smtp_creds["password"],
        )
    except Exception as e:
        logger.error(f"SES alert failed: {e}")

    if failed:
        raise RuntimeError(f"Backup failed for: {', '.join(r['name'] for r in failed)}")

    logger.info(f"Backup complete. Changed: {changed or 'none'}")
    return results


def palo_alto_backup(timer: func.TimerRequest) -> None:
    if timer.past_due:
        logger.warning("Timer is past due — running anyway")
    run_backup()
