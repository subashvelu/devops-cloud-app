FROM python:3.12-slim

# Don't write .pyc files, and print logs immediately (so `docker logs` works well)
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Copy requirements first: Docker caches this layer, so rebuilds are fast
# unless requirements.txt actually changes.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Only the application code is needed at runtime (no tests, no terraform).
COPY app.py .

# Which git commit built this image (passed with --build-arg in deploy.yml)
ARG GIT_SHA=dev
ENV GIT_SHA=$GIT_SHA

# Security: run as a normal user instead of root
RUN useradd --create-home appuser
USER appuser

EXPOSE 5000

# Docker marks the container "healthy"/"unhealthy" using this check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health', timeout=2)"

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "app:app"]
