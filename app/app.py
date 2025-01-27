import os
from flask import Flask

# Load environment variables with defaults where applicable
port = os.getenv("PORT", "5000")  # Default port 5000 if not set
ngrok_token = os.getenv("NGROK_TOKEN")
region = os.getenv("REGION", "ap")  # Default region to "ap"

# Ensure mandatory environment variables are set
if not ngrok_token:
    raise ValueError("Error: Missing NGROK_TOKEN environment variable. Please ensure it's set in the .env file.")

if not port.isdigit():
    raise ValueError(f"Error: Invalid PORT value: '{port}'. It must be a numeric value.")

# Create Flask app
app = Flask(__name__)

@app.route("/")
def hello_world():
    return (
        "<h1><p style='font-family:monospace'>Checkout "
        "<a href='https://github.com/x0rzavi/heroku-vpn'>heroku-vpn</a> on GitHub by "
        "<a href='https://github.com/x0rzavi'>X0rzAvi</a></p></h1>"
    )

if __name__ == "__main__":
    print(f"Starting Flask app on port {port}, with Ngrok region '{region}'")
    app.run(host="0.0.0.0", port=int(port))
