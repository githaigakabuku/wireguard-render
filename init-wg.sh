#!/bin/bash

# Initialize WireGuard server configuration
# This runs once to set up keys and config file

CONFIG_DIR="/config"
INTERFACE="wg0"
PORT="5120"
SUBNET="10.0.0.0/24"
SERVER_IP="10.0.0.1"

# Create config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Generate server private key if it doesn't exist
if [ ! -f "$CONFIG_DIR/server_private.key" ]; then
    echo "Generating server keys..."
    umask 077
    wg genkey | tee "$CONFIG_DIR/server_private.key" | wg pubkey > "$CONFIG_DIR/server_public.key"
fi

# Read keys
SERVER_PRIVATE_KEY=$(cat "$CONFIG_DIR/server_private.key")
SERVER_PUBLIC_KEY=$(cat "$CONFIG_DIR/server_public.key")

# Create WireGuard config if it doesn't exist
if [ ! -f "$CONFIG_DIR/wg0.conf" ]; then
    echo "Creating WireGuard configuration..."
    cat > "$CONFIG_DIR/wg0.conf" << EOF
[Interface]
PrivateKey = $SERVER_PRIVATE_KEY
Address = $SERVER_IP/24
ListenPort = $PORT
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth+ -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth+ -j MASQUERADE
EOF
    chmod 600 "$CONFIG_DIR/wg0.conf"
fi

# Create a peers configuration file for reference
if [ ! -f "$CONFIG_DIR/PEERS.md" ]; then
    cat > "$CONFIG_DIR/PEERS.md" << "EOF"
# WireGuard Peers Configuration

To add a peer, run:
```bash
./add-peer.sh <peer-name>
```

## Server Details
EOF
    echo "Server Public Key: $SERVER_PUBLIC_KEY" >> "$CONFIG_DIR/PEERS.md"
    echo "Server Port: $PORT" >> "$CONFIG_DIR/PEERS.md"
fi

echo "WireGuard initialization complete!"
echo "Server Public Key: $SERVER_PUBLIC_KEY"
