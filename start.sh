#!/bin/bash

# Check if STATIC_IP is set and apply it
if [ -n "$STATIC_IP" ]; then
    echo "Applying static IP: ${STATIC_IP}"
    ifconfig eth0 "${STATIC_IP}" netmask 255.255.255.0 up
else
    echo "No STATIC_IP provided. Using default IP from Docker."
fi

# Ensure NGROK_TOKEN is set
if [ -z "$NGROK_TOKEN" ]; then
    echo "Error: NGROK_TOKEN is not set in the environment variables."
    exit 1
fi

# Ensure PORT is set, default to 22 if not
if [ -z "$PORT" ]; then
    echo "Warning: PORT is not set. Defaulting to 22."
    PORT=22
fi

# Ensure REGION is set, default to 'ap' if not
if [ -z "$REGION" ]; then
    echo "Warning: REGION is not set. Defaulting to 'ap'."
    REGION="ap"
fi

# Start Ngrok TCP tunnel
echo "Starting Ngrok TCP tunnel on port ${PORT} in region ${REGION}..."
/ngrok tcp --authtoken "$NGROK_TOKEN" --region "$REGION" "$PORT" &

NGROK_PID=$!

# Wait for Ngrok to establish the tunnel
sleep 5

# Fetch and display Ngrok tunnel details
TUNNEL_INFO=$(curl -s http://localhost:4040/api/tunnels)

if [ -z "$TUNNEL_INFO" ]; then
    echo "Error: Unable to retrieve Ngrok tunnel details. Check if Ngrok is running and configured correctly."
    kill $NGROK_PID
    exit 1
fi

# Parse and display the public URL for SSH access
PUBLIC_URL=$(echo "$TUNNEL_INFO" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if 'tunnels' in data and len(data['tunnels']) > 0:
        print(data['tunnels'][0]['public_url'])
except Exception as e:
    sys.exit(1)
")

if [ -z "$PUBLIC_URL" ]; then
    echo "Error: Failed to parse Ngrok public URL."
    kill $NGROK_PID
    exit 1
fi

echo -e "SSH Tunnel Information:\nssh root@${PUBLIC_URL:6} -p ${PUBLIC_URL##*:}"
echo "ROOT Password: Yunus2512"

# Start the SSH server
echo "Starting SSH server..."
/usr/sbin/sshd -D

# Stop Ngrok on exit
trap "kill $NGROK_PID" EXIT
