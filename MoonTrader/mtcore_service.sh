#!/bin/bash

SERVICE_FILE="/lib/systemd/system/mtcore.service"

# Create the systemd startup script
echo "[Unit]
Description=MTCore daemon
After=network.target

[Service]
Type=forking
ExecStart=/bin/bash -c 'tmux new-session -d -s mtcore; tmux send-keys -t mtcore:0 /usr/bin/MoonTrader Enter'
ExecStop=/bin/bash -c 'tmux send-keys -t mtcore:0 C-c; sleep 30; tmux kill-session -t mtcore'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target" | tee "$SERVICE_FILE" > /dev/null

# Set proper permissions for the service file
chmod 644 "$SERVICE_FILE"

# Reload systemd daemon
systemctl daemon-reload

# Enable the service
systemctl enable mtcore

# Display success message
echo "MTCore service has been created and enabled."
echo "You can start the service using: systemctl start mtcore"
echo "You can stop the service using: systemctl stop mtcore"
