#!/bin/bash

# Initialize WireGuard server configuration for userspace (wireguard-go)
# This runs once to set up keys and config file

CONFIG_DIR="/config"
INTERFACE="wg0"
PORT="5120"
SERVER_SUBNET="10.0.0.1/24"

set -e

# Create config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Generate server private key if it doesn't exist
if [ ! -f "$CONFIG_DIR/server_private.key" ]; then
    echo "[init-wg] Generating server keys..."
    umask 077
    wg genkey | tee "$CONFIG_DIR/server_private.key" | wg pubkey > "$CONFIG_DIR/server_public.key"
    echo "[init-wg] ✓ Server keys generated"
fi

# Read keys
SERVER_PRIVATE_KEY=$(cat "$CONFIG_DIR/server_private.key")
SERVER_PUBLIC_KEY=$(cat "$CONFIG_DIR/server_public.key")

# Create WireGuard config if it doesn't exist
if [ ! -f "$CONFIG_DIR/wg0.conf" ]; then
    echo "[init-wg] Creating WireGuard configuration..."
    cat > "$CONFIG_DIR/wg0.conf" << EOF
[Interface]
PrivateKey = $SERVER_PRIVATE_KEY
Address = $SERVER_SUBNET
ListenPort = $PORT
EOF
    chmod 600 "$CONFIG_DIR/wg0.conf"
    echo "[init-wg] ✓ WireGuard config created"
fi

# Wait for wg0 interface to be created by wireguard-go
echo "[init-wg] Waiting for wg0 interface..."
sleep 2

# Configure interface if wg0 exists
if ip link show $INTERFACE 2>/dev/null; then
    echo "[init-wg] Configuring $INTERFACE interface..."
    
    # Set interface up with IP
    ip addr add $SERVER_SUBNET dev $INTERFACE 2>/dev/null || true
    ip link set $INTERFACE up
    
    # Load configuration
    wg set $INTERFACE private-key <(cat "$CONFIG_DIR/server_private.key")
    wg set $INTERFACE listen-port $PORT
    
    echo "[init-wg] ✓ Interface configured"
    echo "[init-wg] Server running on UDP port $PORT"
    echo "[init-wg] Server Public Key: $SERVER_PUBLIC_KEY"
else
    echo "[init-wg] wg0 interface not yet available, skipping configuration"
fi

# Create a peers configuration file for reference
if [ ! -f "$CONFIG_DIR/PEERS.md" ]; then
    cat > "$CONFIG_DIR/PEERS.md" << EOF
# WireGuard Peers Configuration

To add a peer, run:
\`\`\`bash
./add-peer.sh <peer-name>
\`\`\`

## Server Details
- Public Key: $SERVER_PUBLIC_KEY
- Listen Port: $PORT
- Subnet: 10.0.0.0/24
- Server IP: 10.0.0.1
EOF
fi

mkdir -p "$CONFIG_DIR/peers"

echo "[init-wg] Initialization complete!"
