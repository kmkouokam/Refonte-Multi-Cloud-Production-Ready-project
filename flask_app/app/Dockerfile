# Base image
FROM python:3.12-slim

# Set working directory
WORKDIR /app

# Copy requirements (create requirements.txt first)
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy app code
COPY . .

# Set environment variable for Flask
ENV FLASK_ENV=production

# Command to run Flask app
CMD ["python", "main.py"]
