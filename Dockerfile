FROM alpine:latest

# Install wireguard-tools and wireguard-go (userspace implementation)
RUN apk add --no-cache \
    wireguard-tools \
    wireguard-go \
    iptables \
    iproute2 \
    busybox-extras \
    bash \
    ca-certificates

EXPOSE 5120/udp

# Create directories
RUN mkdir -p /config /etc/services.d/healthcheck /etc/services.d/wireguard-init

# Copy initialization scripts
COPY init-wg.sh /init-wg.sh
COPY add-peer.sh /add-peer.sh
COPY healthcheck/run /etc/services.d/healthcheck/run
RUN chmod +x /init-wg.sh /add-peer.sh /etc/services.d/healthcheck/run

# Create startup script for wireguard-go
RUN echo '#!/bin/bash\n\
. /etc/profile\n\
umask 077\n\
mkdir -p /config\n\
/init-wg.sh\n\
export PATH="/usr/bin:/bin:/usr/sbin:/sbin"\n\
exec wireguard-go wg0\n\
' > /etc/services.d/wireguard-init/run && chmod +x /etc/services.d/wireguard-init/run

# Setup healthcheck
RUN echo '#!/bin/bash\n\
PORT_VALUE="${PORT:-10000}"\n\
echo "Starting healthcheck server on ${PORT_VALUE}"\n\
/bin/busybox httpd -f -p "${PORT_VALUE}"\n\
' > /etc/services.d/healthcheck/run && chmod +x /etc/services.d/healthcheck/run

# Use s6-overlay for process management
RUN apk add --no-cache s6 s6-overlay
ENV S6_CMD_WAIT_FOR_SERVICES_MAXRETRY=0
ENTRYPOINT ["/init"]
CMD ["s6-svscan", "/etc/services.d"]
