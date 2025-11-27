# Dockerfile — includes gunicorn so CMD works
FROM python:3.12-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Install system/build deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    pkg-config \
    python3-dev \
    ca-certificates \
    curl \
    git \
    ffmpeg \
    libsndfile1 \
    libportaudio2 \
    portaudio19-dev \
    libasound2-dev \
  && rm -rf /var/lib/apt/lists/*

# Copy requirements first for caching
COPY requirements.txt /app/requirements.txt

# Upgrade pip tooling
RUN pip install --upgrade pip setuptools wheel

# Install Python deps from requirements.txt
RUN pip install --no-cache-dir --prefer-binary -r /app/requirements.txt

# Ensure gunicorn is installed (in case it's not in requirements.txt)
RUN pip install --no-cache-dir gunicorn

# Copy application code
COPY . /app

EXPOSE 5000

# Use gunicorn for the Flask app (Render sets $PORT). Fallback to 5000 locally.
CMD ["sh", "-c", "exec gunicorn --bind 0.0.0.0:${PORT:-5000} --workers 1 --threads 4 --timeout 300 app:app"]
