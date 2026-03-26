#!/bin/bash

set -euo pipefail

PORT_VALUE="${PORT:-10000}"
WG_INTERFACE="wg0"
WG_ADDRESS="10.0.0.1/24"
WG_UDP_PORT="${SERVERPORT:-5120}"

echo "[start] Starting healthcheck HTTP server on ${PORT_VALUE}"
# Render requires a TCP listener on $PORT for web services.
busybox httpd -f -p "${PORT_VALUE}" &
HEALTHCHECK_PID=$!

# Ensure keys/config exist.
/init-wg.sh

echo "[start] Launching wireguard-go on ${WG_INTERFACE}"
wireguard-go "${WG_INTERFACE}" &
WG_GO_PID=$!

# Give interface a moment to appear.
sleep 2

if ip link show "${WG_INTERFACE}" >/dev/null 2>&1; then
  echo "[start] Configuring ${WG_INTERFACE}"
  wg set "${WG_INTERFACE}" private-key /config/server_private.key listen-port "${WG_UDP_PORT}"
  ip addr add "${WG_ADDRESS}" dev "${WG_INTERFACE}" 2>/dev/null || true
  ip link set "${WG_INTERFACE}" up
  echo "[start] WireGuard is up on UDP ${WG_UDP_PORT}"
else
  echo "[start] ERROR: ${WG_INTERFACE} interface was not created"
  exit 1
fi

# Exit cleanly if either critical process dies.
wait -n "${HEALTHCHECK_PID}" "${WG_GO_PID}"
exit 1
