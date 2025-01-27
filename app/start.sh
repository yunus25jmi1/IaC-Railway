#!/bin/sh

# Ensure necessary environment variables are set
if [ -z "$PORT" ]; then
    echo "Error: Missing PORT environment variable. Defaulting to 5000."
    PORT=5000
fi

# Start Gunicorn server to run the Flask app
echo "Starting Gunicorn server on port ${PORT}..."
gunicorn --bind "0.0.0.0:${PORT}" --workers 2 --threads 2 app.wsgi:app
