#!/bin/bash

SERVICE_FILE="/lib/systemd/system/botclient.service"

# Create the systemd startup script
echo "[Unit]
Description=BotClient daemon
After=network.target

[Service]
Type=forking
ExecStart=/bin/bash -c 'tmux new-session -d -s botclient; tmux send-keys -t botclient:0 /root/MoonTrader/BotClient/BotClient Enter'
ExecStop=/bin/bash -c 'tmux send-keys -t botclient:0 C-c; sleep 10; tmux kill-session -t botclient'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target" | tee "$SERVICE_FILE" > /dev/null

# Set proper permissions for the service file
chmod 644 "$SERVICE_FILE"

# Reload systemd daemon
systemctl daemon-reload

# Enable the service
systemctl enable botclient

# Display success message
echo "BotClient service has been created and enabled."
echo "You can start the service using: systemctl start botclient"
echo "You can stop the service using: systemctl stop botclient"
