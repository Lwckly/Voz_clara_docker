# Fixed Dockerfile — installs PortAudio headers so PyAudio wheel builds
FROM python:3.12-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Install system/build deps in one RUN (no stray tokens)
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

# Copy requirements first for better caching
COPY requirements.txt /app/requirements.txt

# Upgrade pip tooling
RUN pip install --upgrade pip setuptools wheel

# If you need a pinned CPU torch wheel, install it here (uncomment & set version)
# RUN pip install --no-cache-dir torch==2.2.0+cpu -f https://download.pytorch.org/whl/cpu/torch_stable.html

# Install Python dependencies
RUN pip install --no-cache-dir --prefer-binary -r /app/requirements.txt

# Copy application code
COPY . /app

EXPOSE 5000

# Use gunicorn for production; fallback to `python app.py` if you prefer
CMD ["sh", "-c", "exec gunicorn --bind 0.0.0.0:${PORT:-5000} --workers 1 --threads 4 --timeout 300 app:app"]
