FROM alpine:latest

# Install wireguard-tools and wireguard-go (userspace implementation)
RUN apk add --no-cache \
    wireguard-tools \
    wireguard-go \
    iproute2 \
    busybox \
    bash \
    ca-certificates

EXPOSE 5120/udp

# Create directories
RUN mkdir -p /config

# Copy initialization scripts
COPY init-wg.sh /init-wg.sh
COPY add-peer.sh /add-peer.sh
COPY start.sh /start.sh
RUN chmod +x /init-wg.sh /add-peer.sh /start.sh

CMD ["/start.sh"]
