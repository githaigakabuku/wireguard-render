FROM linuxserver/wireguard

ENV PUID=1000
ENV PGID=1000
ENV TZ=Etc/UTC

EXPOSE 5120/udp

RUN mkdir -p /etc/services.d/healthcheck
COPY healthcheck/run /etc/services.d/healthcheck/run
RUN chmod +x /etc/services.d/healthcheck/run

# Copy initialization scripts
COPY init-wg.sh /init-wg.sh
COPY add-peer.sh /add-peer.sh
RUN chmod +x /init-wg.sh /add-peer.sh

# Run init on startup
RUN mkdir -p /etc/services.d/wireguard-init
RUN echo '#!/bin/bash\n/init-wg.sh' > /etc/services.d/wireguard-init/run && chmod +x /etc/services.d/wireguard-init/run

CMD ["/init"]
