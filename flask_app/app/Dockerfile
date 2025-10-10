# Base image
FROM python:3.12-slim

# Set working directory
WORKDIR /app

# Copy requirements
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the entire app
COPY . .

# Expose port (match your service targetPort)
EXPOSE 5000

# Use environment variable for Flask environment (optional default)
ENV FLASK_ENV=production

# Run the app with Gunicorn
# main:app -> refers to 'app' Flask instance in main.py
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "main:app"]
