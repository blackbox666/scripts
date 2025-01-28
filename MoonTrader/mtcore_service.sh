#!/bin/bash

SERVICE_FILE="/lib/systemd/system/mtcore.service"

# Create the systemd startup script
cat << 'EOF' > "$SERVICE_FILE"
[Unit]
Description=MTCore daemon
After=network-online.target
Wants=network-online.target
StartLimitIntervalSec=300
StartLimitBurst=5

[Service]
Type=forking
ExecStart=/bin/bash -c '\
    tmux new-session -d -s mtcore; \
    tmux send-keys -t mtcore:0 /usr/bin/MoonTrader Enter'
ExecStop=/bin/bash -c '\
    tmux send-keys -t mtcore:0 C-c || true; \
    sleep 30; \
    if tmux list-sessions | grep -q mtcore; then \
        tmux send-keys -t mtcore:0 C-c || true; \
        sleep 5; \
        tmux kill-session -t mtcore || true; \
    fi'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

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