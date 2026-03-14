FROM python:3.11-slim

# Install Checkov and dependencies for better reports
RUN pip install --no-cache-dir \
    checkov \
    jinja2 \
    tabulate

# Create output directory
RUN mkdir -p /reports

WORKDIR /scan

ENTRYPOINT ["checkov"]
CMD ["--help"]