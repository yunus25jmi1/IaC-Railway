if [ -z "${NGROK_TOKEN}" ]; then
    echo "Error: NGROK_TOKEN is not set. Please set it in your .env file." >&2
    exit 1
fi

if [ -z "${REGION}" ]; then
    echo "Warning: REGION is not set. Defaulting to 'us' region."
    REGION="us"
fi
# Update to use proper config location
if [ -z "${BASE_CONF}" ]; then
    echo "Error: BASE_CONF is not set" >&2
    exit 1
fi

echo "Decoding Rclone configuration..."
echo $BASE_CONF | base64 -d > /app/.rclone.conf
chmod 600 /app/.rclone.conf

echo "Starting Rclone SFTP server..."
rclone --config /app/.rclone.conf serve sftp "$CLOUD_NAME":$SUB_DIR \
    --no-auth \
    --vfs-cache-mode full \
    --log-level DEBUG &
