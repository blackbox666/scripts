#!/bin/bash

SERVICE_FILE="/lib/systemd/system/mtcore.service"

# Create the systemd startup script
echo "[Unit]
Description=MTCore daemon
After=network.target

[Service]
Type=forking
ExecStart=/usr/bin/tmux new-session -d -s mtcore /root/MoonTrader/MTCore
ExecStop=/bin/bash -c 'tmux send-keys -t mtcore:0 C-c; sleep 10; tmux kill-session -t mtcore'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target" | sudo tee "$SERVICE_FILE" > /dev/null

# Set proper permissions for the service file
sudo chmod 644 "$SERVICE_FILE"

# Reload systemd daemon
sudo systemctl daemon-reload

# Enable the service
sudo systemctl enable mtcore

# Display success message
echo "MTCore service has been created and enabled."
echo "You can start the service using: sudo systemctl start mtcore"
echo "You can stop the service using: sudo systemctl stop mtcore"
