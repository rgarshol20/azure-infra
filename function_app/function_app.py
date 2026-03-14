import json
import logging

import azure.functions as func

from palo_alto_backup.backup_handler import palo_alto_backup as _backup, run_backup

logger = logging.getLogger(__name__)

app = func.FunctionApp()


@app.timer_trigger(
    schedule="30 2 * * *",
    arg_name="timer",
    run_on_startup=True,  # fires immediately on container start — enables on-demand via az container stop/start
    use_monitor=True,
)
def palo_alto_backup(timer: func.TimerRequest) -> None:
    _backup(timer)


@app.route(route="run", methods=["POST"], auth_level=func.AuthLevel.ANONYMOUS)
def run_on_demand(req: func.HttpRequest) -> func.HttpResponse:
    """HTTP trigger for on-demand backup.

    POST /api/run — run backup

    Response: JSON with backup results.
    Email alerts are sent exactly as they would be on a timer run.
    """
    response: dict = {}
    try:
        logger.info("on-demand: running backup")
        backup_results = run_backup()
        response["backup"] = [
            {k: v for k, v in r.items() if k != "config_xml"}
            for r in backup_results
        ]
    except Exception as e:
        logger.error(f"on-demand run failed: {e}", exc_info=True)
        response["error"] = str(e)
        return func.HttpResponse(
            json.dumps(response), status_code=500, mimetype="application/json",
        )

    return func.HttpResponse(json.dumps(response), mimetype="application/json")
