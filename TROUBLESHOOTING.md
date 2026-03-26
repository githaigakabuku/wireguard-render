# Troubleshooting WireGuard Deployment on Render.com

## Issue: "WireGuard module is not active"

**Solution:** This deployment now uses **wireguard-go** (userspace implementation) which doesn't require kernel modules. Redeploy with the updated Dockerfile.

```bash
git pull origin main
git push origin main  # Trigger new deployment on Render
```

## Issue: Deployment fails immediately

**Solution:** Check the build logs in Render dashboard:
1. Go to Services → Your WireGuard Service
2. Click "Logs"
3. Look for errors in the build phase

Common causes:
- Missing files (ensure all `.sh` scripts are pushed)
- Invalid Dockerfile syntax (check for typos)
- Alpine package name changes

## Issue: Container runs but peers can't connect

**Checklist:**
- [ ] Replace `YOUR_SERVER_IP` in peer configs with actual server IP
- [ ] Server IP is listed in Render dashboard (Services → Environment)
- [ ] UDP port 5120 is accessible from outside (check firewall)
- [ ] Peer IP assignments are correct (check `/config/PEERS.md`)

**To verify server is running:**
```bash
# In Render shell
ps aux | grep wireguard-go
# Should show wireguard-go wg0 process

# Check interface
ip link show wg0
ip addr show wg0

# Check open ports
netstat -ulpn | grep 5120
```

## Issue: Can't access Render shell

**Solution:**
1. Go to Render Dashboard → Services → Your WireGuard Service
2. Click "Shell" in the top menu
3. If Shell button is grayed out, service needs to be running

## Issue: Persistent config disk shows error

**Solution:** The 1GB disk should be automatically created. If missing:
1. Delete and recreate the service
2. Ensure `render.yaml` has correct disk configuration:
   ```yaml
   disk:
     name: wireguard-data
     mountPath: /config
     sizeGB: 1
   ```

## Issue: Peer can connect but can't access VPN routes

**Current limitation:** This deployment creates the VPN tunnel but routing/NAT rules may not work on Render's restricted environment. Peers can communicate with the server but may not reach other networks through it.

**Possible solutions:**
- Use this as a proxy/gateway access point only
- Host on unrestricted VPS (DigitalOcean, Linode, Vultr) instead

## Issue: Port 5120 shows as closed externally

**Solution:**
1. Verify in `render.yaml`:
   ```yaml
   ports:
     - port: 5120
       protocol: udp
   ```
2. UDP ports take ~1 minute to fully open after deployment
3. Wait 2-3 minutes and retry

## Debug Information

Get full server status:
```bash
# In Render shell
cat /config/PEERS.md
cat /config/server_public.key
ls -la /config/peers/
ps aux | grep wg
```

Check interface configuration:
```bash
wg show wg0
```

## Still Having Issues?

1. Check Render service logs (Logs tab)
2. Look for errors in `/var/log/` (if accessible)
3. Verify all `.sh` files have execute permissions
4. Ensure Dockerfile builds without errors

For complex issues, consider:
- Testing locally with Docker
- Using a different hosting platform
- Using traditional OpenVPN instead
