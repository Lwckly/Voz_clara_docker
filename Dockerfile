# Use a small stable Python base
FROM python:3.11-slim

# Prevent Python from writing .pyc and enable unbuffered stdout (logs)
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Install system packages needed by ffmpeg, librosa, pydub and some wheels
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    ffmpeg \
    libsndfile1 \
    libsndfile1-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for Docker layer caching
COPY requirements.txt /app/requirements.txt

# Upgrade pip then install python deps
RUN pip install --upgrade pip setuptools wheel \
 && pip install -r /app/requirements.txt

# Copy application code
COPY . /app

# Expose default port (Render sets $PORT env for you)
EXPOSE 5000

# Use gunicorn to serve the Flask app. Render will provide $PORT
# Use a moderate timeout cause model loading / cold starts can take time.
CMD ["sh", "-c", "exec gunicorn --bind 0.0.0.0:${PORT:-5000} --workers 1 --threads 4 --timeout 300 app:app"]
