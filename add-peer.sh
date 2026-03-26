#!/bin/bash

# Add a WireGuard peer (client)

CONFIG_DIR="/config"
PEERS_DIR="$CONFIG_DIR/peers"
INTERFACE="wg0"
SERVER_IP="10.0.0.1/24"

if [ $# -ne 1 ]; then
    echo "Usage: $0 <peer-name>"
    echo "Example: $0 laptop"
    exit 1
fi

PEER_NAME="$1"
PEER_DIR="$PEERS_DIR/$PEER_NAME"

# Check if peer already exists
if [ -d "$PEER_DIR" ]; then
    echo "[add-peer] Peer '$PEER_NAME' already exists at $PEER_DIR"
    exit 1
fi

mkdir -p "$PEER_DIR"

# Generate peer keys
echo "[add-peer] Generating keys for peer '$PEER_NAME'..."
umask 077
wg genkey | tee "$PEER_DIR/private.key" | wg pubkey > "$PEER_DIR/public.key"

PEER_PRIVATE_KEY=$(cat "$PEER_DIR/private.key")
PEER_PUBLIC_KEY=$(cat "$PEER_DIR/public.key")

# Assign IP address based on peer count
PEER_COUNT=$(ls -1d "$PEERS_DIR"/* 2>/dev/null | wc -l)
PEER_IP="10.0.0.$((PEER_COUNT + 2))"

# Get server public key
if [ ! -f "$CONFIG_DIR/server_public.key" ]; then
    echo "[add-peer] Error: Server not initialized. Run /init-wg.sh first."
    exit 1
fi
SERVER_PUBLIC_KEY=$(cat "$CONFIG_DIR/server_public.key")

# Try to add peer to interface if available
if command -v wg &> /dev/null && ip link show $INTERFACE 2>/dev/null; then
    echo "[add-peer] Adding peer to WireGuard interface..."
    wg set $INTERFACE peer "$PEER_PUBLIC_KEY" allowed-ips "$PEER_IP/32" 2>/dev/null || \
        echo "[add-peer] ⚠ Could not add to live interface (may configure on next restart)"
fi

# Save peer configs
ENDPOINT_PLACEHOLDER="YOUR_SERVER_IP"

cat > "$PEER_DIR/config.txt" << EOF
# WireGuard Configuration for: $PEER_NAME
# Generated: $(date)

[Interface]
PrivateKey = $PEER_PRIVATE_KEY
Address = $PEER_IP/32
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $ENDPOINT_PLACEHOLDER:5120
AllowedIPs = 10.0.0.0/24
PersistentKeepalive = 25
EOF

# Also create the format for wg-quick
cat > "$PEER_DIR/wg0.conf" << EOF
[Interface]
PrivateKey = $PEER_PRIVATE_KEY
Address = $PEER_IP/32
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $ENDPOINT_PLACEHOLDER:5120
AllowedIPs = 10.0.0.0/24
PersistentKeepalive = 25
EOF

# Generate QR code compatible format
cat > "$PEER_DIR/qr.conf" << EOF
[Interface]
PrivateKey = $PEER_PRIVATE_KEY
Address = $PEER_IP/32
DNS = 1.1.1.1

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $ENDPOINT_PLACEHOLDER:5120
AllowedIPs = 10.0.0.0/24
EOF

echo ""
echo "[add-peer] ✓ Peer '$PEER_NAME' created successfully!"
echo ""
echo "  Peer IP: $PEER_IP"
echo "  Private Key: $PEER_DIR/private.key"
echo "  Public Key: $PEER_DIR/public.key"
echo ""
echo "Configuration files:"
echo "  - $PEER_DIR/config.txt (standard format)"
echo "  - $PEER_DIR/wg0.conf (wg-quick format)"
echo "  - $PEER_DIR/qr.conf (for QR code generation)"
echo ""
echo "⚠ IMPORTANT: Replace '$ENDPOINT_PLACEHOLDER' with your server's IP address!"
echo ""
echo "Your server's public IP: Check Render dashboard Services → Your Service"
