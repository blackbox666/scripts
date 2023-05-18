#!/bin/bash

SERVICE_PREFIX="mtcore"

# Prompt user for service instance
read -p "Enter MTCore profile name (case-sensitive): " SERVICE_INSTANCE

# Prompt user for instance port
read -p "Enter instance port (e.g. 4243): " INSTANCE_PORT

# Define service name
SERVICE_NAME="${SERVICE_PREFIX}-${SERVICE_INSTANCE}"
SERVICE_FILE="/lib/systemd/system/${SERVICE_NAME}.service"

# Create the systemd startup script
echo "[Unit]
Description=MTCore daemon
After=network.target

[Service]
Type=forking
ExecStart=/usr/bin/tmux new-session -d -s "${SERVICE_NAME}" /root/MoonTrader/MTCore --profile "$SERVICE_INSTANCE" --port "$INSTANCE_PORT"
ExecStop=/bin/bash -c 'tmux send-keys -t "${SERVICE_NAME}":0 C-c; sleep 30; tmux kill-session -t "${SERVICE_NAME}"'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target" | sudo tee "$SERVICE_FILE" > /dev/null

# Set proper permissions for the service file
sudo chmod 644 "$SERVICE_FILE"

# Reload systemd daemon
sudo systemctl daemon-reload

# Enable the service
sudo systemctl enable "$SERVICE_NAME"

# Display success message
echo "MTCore service ($SERVICE_NAME) has been created and enabled."
echo "You can start the service using: sudo systemctl start $SERVICE_NAME"
echo "You can stop the service using: sudo systemctl stop $SERVICE_NAME"
