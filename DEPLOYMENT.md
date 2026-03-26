# WireGuard Deployment Setup Guide

## What Gets Deployed

1. **WireGuard VPN Server** - Userspace implementation using `wireguard-go` (no kernel module required)
2. **Initialization Scripts** - Sets up keys and server configuration on first run
3. **Peer Management** - Scripts to add WireGuard clients (peers)
4. **Healthcheck Service** - HTTP server for Render's port monitoring

## Why wireguard-go?

Render.com containers don't allow kernel module loading. This deployment uses **wireguard-go** (userspace WireGuard implementation) which:

- ✓ Requires no kernel module
- ✓ Works on restricted container environments
- ✓ Provides full WireGuard encryption & functionality
- ✓ Slightly higher CPU usage than kernel module (still minimal)

## Files in This Deployment

| File              | Purpose                                                      |
| ----------------- | ------------------------------------------------------------ |
| `Dockerfile`      | Builds the container with WireGuard + initialization scripts |
| `render.yaml`     | Render.com deployment configuration                          |
| `init-wg.sh`      | Initializes WireGuard server on first run                    |
| `add-peer.sh`     | Adds new VPN clients/peers                                   |
| `healthcheck/run` | Health check service (required by Render)                    |

## Deployment Flow

### 1. **On Container Startup**

- Initialization service runs `init-wg.sh`
- Generates server private/public keys (if first run)
- Creates WireGuard interface config
- Healthcheck service starts HTTP server on `$PORT`

### 2. **After Deployment**

- Access container via Render shell
- Run `./add-peer.sh <client-name>` to create VPN clients
- Share generated configs with your devices

## How to Deploy

1. Push to GitHub
2. Go to [Render.com](https://render.com)
3. Create new Web Service
4. Connect GitHub and select this repo
5. Deploy on Starter plan
6. Wait for deployment to complete

## After Deployment

### Access the Container Shell

```bash
# Via Render Dashboard: Services → Your WireGuard Service → Shell
```

### Add a VPN Client

```bash
./add-peer.sh laptop
./add-peer.sh phone
./add-peer.sh work
```

### Get Peer Configs

```bash
# View server public key
cat /config/server_public.key

# View all peer configs
cat /config/peers/*/config.txt
```

### Mount the Config Disk

- Render automatically mounts `/config` to a persistent 1GB disk
- All WireGuard configs, keys, and peer data persist between restarts

## Configuration Files

**Server Config:** `/config/wg0.conf`

- Server private key
- Server IP: 10.0.0.1/24
- Listen port: 5120 (UDP)

**Peer Configs:** `/config/peers/<peer-name>/`

- `private.key` - Peer's private key
- `public.key` - Peer's public key
- `config.txt` - Full configuration
- `wg_quick.conf` - Quick connect config

## Important Notes

- ⚠️ Replace `YOUR_SERVER_IP` in peer configs with your Render service's public IP
- The subnet is `10.0.0.0/24` - supports up to 254 peers
- Peers connect to the VPN server on UDP port 5120
- All traffic is encrypted with WireGuard
