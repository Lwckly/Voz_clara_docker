# Dockerfile — fixes PyAudio wheel build by installing PortAudio dev libs + compiler
FROM python:3.12-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Install system packages needed for audio libs and building Python extensions
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \             # compiler, make, etc. — needed to build wheels
    pkg-config \                  # helps find libs
    libsndfile1 \                 # for librosa / soundfile
    ffmpeg \                      # for pydub/ffmpeg usage
    libportaudio2 \               # PortAudio runtime
    portaudio19-dev \             # PortAudio headers (required to compile PyAudio)
    libasound2-dev \              # ALSA dev libs (sometimes required)
    ca-certificates \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements early for caching
COPY requirements.txt /app/requirements.txt

# Upgrade pip tooling and ensure wheel is present
RUN pip install --upgrade pip setuptools wheel

# Optional: if you need PyTorch CPU wheel pinned, install it here (uncomment and set version)
# RUN pip install --no-cache-dir torch==2.2.0+cpu -f https://download.pytorch.org/whl/cpu/torch_stable.html

# Install Python dependencies (prefer binary wheels where available)
RUN pip install --no-cache-dir --prefer-binary -r /app/requirements.txt

# Copy application code
COPY . /app

EXPOSE 5000

# Use gunicorn in production if you prefer; fallback to `python app.py`
CMD ["sh", "-c", "exec gunicorn --bind 0.0.0.0:${PORT:-5000} --workers 1 --threads 4 --timeout 300 app:app"]
