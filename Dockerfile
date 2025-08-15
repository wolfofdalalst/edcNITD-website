# syntax=docker/dockerfile:1

FROM python:3.9-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# System deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir gunicorn

# Copy project
COPY website /app/website

# Create non-root user
RUN useradd -m appuser
USER appuser

# Expose port
EXPOSE 8000

# Default command (can be overridden by docker-compose)
CMD ["gunicorn", "website.wsgi:application", "--chdir", "/app/website", "--bind", "0.0.0.0:8000", "--workers", "3"]
