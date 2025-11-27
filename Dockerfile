# Use Python 3.12 (Render supports this)
FROM python:3.12-slim

# Prevent Python from writing .pyc files and forcing UTF-8
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        ffmpeg \
        libsndfile1 \
        libgl1 \
        && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy only requirements first (better Docker caching)
COPY requirements.txt /app/

# Install Python dependencies
RUN pip install --upgrade pip setuptools wheel
RUN pip install --no-cache-dir --prefer-binary -r requirements.txt

# Copy app code
COPY . /app/

# Expose server port (Render auto-detects)
EXPOSE 5000

# Run the app
CMD ["python", "app.py"]
