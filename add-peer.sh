#!/bin/bash

# Add a WireGuard peer (client)

CONFIG_DIR="/config"
PEERS_DIR="$CONFIG_DIR/peers"
INTERFACE="wg0"
SUBNET="10.0.0.0/24"
SERVER_IP="10.0.0.1"

if [ $# -ne 1 ]; then
    echo "Usage: $0 <peer-name>"
    exit 1
fi

PEER_NAME="$1"
PEER_DIR="$PEERS_DIR/$PEER_NAME"

# Check if peer already exists
if [ -d "$PEER_DIR" ]; then
    echo "Peer '$PEER_NAME' already exists at $PEER_DIR"
    exit 1
fi

mkdir -p "$PEER_DIR"

# Generate peer keys
echo "Generating keys for peer '$PEER_NAME'..."
umask 077
wg genkey | tee "$PEER_DIR/private.key" | wg pubkey > "$PEER_DIR/public.key"

PEER_PRIVATE_KEY=$(cat "$PEER_DIR/private.key")
PEER_PUBLIC_KEY=$(cat "$PEER_DIR/public.key")

# Assign IP address based on peer count
PEER_COUNT=$(ls -1d "$PEERS_DIR"/* 2>/dev/null | wc -l)
PEER_IP="10.0.0.$((PEER_COUNT + 2))"

# Add peer to server config
echo "Adding peer to WireGuard interface..."
wg set $INTERFACE peer "$PEER_PUBLIC_KEY" allowed-ips "$PEER_IP/32"

# Save peer info
cat > "$PEER_DIR/config.txt" << EOF
# WireGuard Peer Configuration for: $PEER_NAME

[Interface]
PrivateKey = $PEER_PRIVATE_KEY
Address = $PEER_IP/24
DNS = 8.8.8.8, 8.8.4.4

[Peer]
PublicKey = $(cat "$CONFIG_DIR/server_public.key")
Endpoint = YOUR_SERVER_IP:5120
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

# Generate QR code config
cat > "$PEER_DIR/wg_quick.conf" << EOF
[Interface]
PrivateKey = $PEER_PRIVATE_KEY
Address = $PEER_IP/24
DNS = 8.8.8.8, 8.8.4.4

[Peer]
PublicKey = $(cat "$CONFIG_DIR/server_public.key")
Endpoint = YOUR_SERVER_IP:5120
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

echo ""
echo "✓ Peer '$PEER_NAME' created successfully!"
echo "  IP Address: $PEER_IP"
echo "  Config file: $PEER_DIR/config.txt"
echo "  Quick config: $PEER_DIR/wg_quick.conf"
echo ""
echo "Don't forget to replace 'YOUR_SERVER_IP' with your Render server's public IP!"
