#!/bin/bash

# Load environment variables from .env if available
if [[ -f /app/.env ]]; then
    export $(grep -v '^#' /app/.env | xargs)
fi

# Ensure required environment variables are set
if [[ -z "$NGROK_TOKEN" ]]; then
    echo "Error: Missing NGROK_TOKEN environment variable. Please set it in the .env file."
    exit 1
fi

if [[ -z "$PORT" ]]; then
    echo "Warning: PORT environment variable not set. Defaulting to 22."
    PORT=22
fi
if [[ -z "$REGION" ]]; then
    echo "Warning: REGION environment variable not set. Defaulting to 'ap'."
    REGION="ap"
fi
# Check if Ngrok binary exists
if [[ ! -f /usr/local/bin/ngrok ]]; then
    echo "Error: Ngrok binary not found. Please ensure Ngrok is installed correctly."
    exit 1
fi
# Start Ngrok TCP tunnel
echo "Starting Ngrok TCP tunnel on port ${PORT} in region ${REGION}..."
/usr/local/bin/ngrok tcp --authtoken="${NGROK_TOKEN}" --region="${REGION}" ${PORT} &
NGROK_PID=$!
# Wait for Ngrok to initialize and retrieve tunnel details
sleep 5
TUNNEL_INFO=$(curl -s http://localhost:4040/api/tunnels)
if [[ -z "$TUNNEL_INFO" ]]; then
    echo "Error: Failed to retrieve Ngrok tunnel details. Ensure Ngrok is running correctly."
    kill $NGROK_PID
    exit 1
fi
# Extract public URL for SSH access
PUBLIC_URL=$(echo "$TUNNEL_INFO" | python3 -c "
import sys, json
data = json.load(sys.stdin)
if 'tunnels' in data and len(data['tunnels']) > 0:
    print(data['tunnels'][0]['public_url'][6:].replace(':', ' -p '))
")
if [[ -z "$PUBLIC_URL" ]]; then
    echo "Error: Unable to extract public URL from Ngrok tunnel information."
    kill $NGROK_PID
    exit 1
fi
echo -e "SSH Info:\nssh root@$PUBLIC_URL\nROOT Password: Demo1234"
# Start OpenSSH server
# Start SSH server
echo "Starting OpenSSH server..."
/usr/sbin/sshd -D
