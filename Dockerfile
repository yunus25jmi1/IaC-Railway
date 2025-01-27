# Base image for Python app with Ubuntu
FROM python:3.12-slim AS app

# Set up directories and environment
RUN mkdir -p /app
WORKDIR /app

# Install system dependencies
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    ssh \
    wget \
    curl \
    vim \
    sudo \
    tmux \
    net-tools \
    iputils-ping \
    gnupg \
    lsb-release \
    rclone \
    apt-utils \
    && rm -rf /var/lib/apt/lists/*

# Install Ngrok
RUN mkdir -p /etc/apt/trusted.gpg.d && \
    curl -fsSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc | \
    gpg --dearmor -o /etc/apt/trusted.gpg.d/ngrok.gpg && \
    echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | \
    tee /etc/apt/sources.list.d/ngrok.list && \
    apt-get update && \
    apt-get install -y ngrok

# Copy and install Python requirements
COPY ./app/requirements.txt /app/app/
RUN pip install --no-cache-dir -r /app/app/requirements.txt

# Copy application code
COPY ./app /app/app

# Configure SSH
RUN mkdir /run/sshd && \
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && \
    echo "root:Demo1234" | chpasswd

# Copy configuration files
RUN mkdir -p /.config/rclone/
COPY rclone.conf /.config/rclone/
COPY deploy-container/rclone-tasks.json /tmp/rclone-tasks.json
COPY openssh.sh /openssh.sh

# Set environment variables
ENV PATH="/usr/bin:/usr/sbin:${PATH}"
ENV RCLONE_CONFIG=/app/.rclone.conf

# Set permissions
RUN chmod +x /openssh.sh

# Expose ports
EXPOSE 22 80 443 3306 4040 5432 5700 5701 5010 6800 6900 8080 8888 9000 7800 3000 9800

# Entrypoint to start services
CMD ["/openssh.sh", "/app/app/start.sh"]