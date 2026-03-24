FROM linuxserver/wireguard

ENV PUID=1000
ENV PGID=1000
ENV TZ=Etc/UTC

EXPOSE 5120/udp

RUN mkdir -p /etc/services.d/healthcheck
COPY healthcheck/run /etc/services.d/healthcheck/run
RUN chmod +x /etc/services.d/healthcheck/run

CMD ["/init"]
