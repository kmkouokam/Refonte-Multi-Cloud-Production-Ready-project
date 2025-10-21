# Use official Python 3.12 slim image
FROM python:3.12-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8080

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    gcc \
    sqlite3 \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt \
    && pip install --no-cache-dir gunicorn==21.2.0

# Copy all project files
COPY . .

# Expose port
EXPOSE ${PORT}

 
 


# Run database initialization, then Gunicorn (Terraform-recommended JSON form)
CMD ["sh", "-c", "python create_db.py && gunicorn --bind 0.0.0.0:8080 project.app:app --workers 2 --threads 4"]
 