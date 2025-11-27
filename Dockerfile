# Robust Dockerfile to reduce apt-get failures
FROM python:3.11-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV TRANSFORMERS_CACHE=/tmp/hf_cache
ENV TORCH_HOME=/tmp/torch_cache

WORKDIR /app

# Use a safer apt sequence with retries and allow-releaseinfo-change fallback.
# Also keep the list of installed packages minimal; add extras only if build logs show they are needed.
RUN set -eux; \
    apt-get update -o Acquire::Retries=3 || { apt-get update -o Acquire::Retries=3 --allow-releaseinfo-change; }; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
        build-essential \
        git \
        ffmpeg \
        libsndfile1 \
        libsndfile1-dev \
        pkg-config \
        # libatlas-base-dev removed here because it's heavy; re-add if you need BLAS for some packages
    ; \
    apt-get clean; rm -rf /var/lib/apt/lists/*

# Copy requirements first to leverage caching
COPY requirements.txt /app/requirements.txt

# Upgrade pip tooling
RUN pip install --upgrade pip setuptools wheel

# Install PyTorch CPU wheel explicitly — remove torch from requirements.txt if you use this line
RUN pip install --no-cache-dir torch==2.2.0+cpu -f https://download.pytorch.org/whl/cpu/torch_stable.html

# Install remaining Python deps; prefer binary wheels
RUN pip install --no-cache-dir --prefer-binary -r /app/requirements.txt

# Copy app code
COPY . /app

EXPOSE 5000

CMD ["sh", "-c", "exec gunicorn --bind 0.0.0.0:${PORT:-5000} --workers 1 --threads 4 --timeout 300 app:app"]
