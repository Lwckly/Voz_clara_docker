# Use a small stable Python base
FROM python:3.11-slim

# noninteractive for apt, reduce Python noise
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
# Optionally set HF/torch cache locations to control disk usage
ENV TRANSFORMERS_CACHE=/tmp/hf_cache
ENV TORCH_HOME=/tmp/torch_cache

WORKDIR /app

# Install system/build deps required by many audio/math packages and ffmpeg for pydub
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    curl \
    ca-certificates \
    ffmpeg \
    libsndfile1 \
    libsndfile1-dev \
    libatlas-base-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first to leverage Docker layer caching
COPY requirements.txt /app/requirements.txt

# Upgrade pip + wheel tooling
RUN pip install --upgrade pip setuptools wheel

# ----- IMPORTANT -----
# Install PyTorch CPU wheel explicitly BEFORE installing the rest of requirements.
# Replace the version below with the version you tested locally if needed.
# Also: REMOVE `torch` from requirements.txt to avoid pip resolving a different wheel.
RUN pip install --no-cache-dir torch==2.2.0+cpu -f https://download.pytorch.org/whl/cpu/torch_stable.html

# Install the remaining Python dependencies from requirements.txt
# --prefer-binary reduces chance pip tries to compile something from source
RUN pip install --no-cache-dir --prefer-binary -r /app/requirements.txt

# Copy application code
COPY . /app

# Expose default port (Render sets $PORT env for you)
EXPOSE 5000

# Use gunicorn as entrypoint. RENDER injects $PORT; fallback to 5000 locally
CMD ["sh", "-c", "exec gunicorn --bind 0.0.0.0:${PORT:-5000} --workers 1 --threads 4 --timeout 300 app:app"]
