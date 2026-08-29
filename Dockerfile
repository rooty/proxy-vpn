# syntax=docker/dockerfile:1
FROM alpine:latest

LABEL org.opencontainers.image.source="https://github.com/rooty/proxy-vpn"
LABEL org.opencontainers.image.description="OpenVPN+Proxy"
LABEL org.opencontainers.image.licenses=MIT

ARG TARGETARCH=amd64

# Install packages
RUN apk --no-cache add \
        runit \
        curl \
        openvpn \
        apache2-utils \
        bash \
        jq \
    && rm -rf /var/cache/apk/*

RUN curl -fsSL "https://github.com/SenseUnit/dumbproxy/releases/latest/download/dumbproxy.linux-${TARGETARCH}" \
        -o /usr/local/bin/dumbproxy \
    && chmod +x /usr/local/bin/dumbproxy

# Add configuration files
COPY --chown=nobody rootfs/ /

# Add application
WORKDIR /etc/openvpn

# Expose the port nginx is reachable on
EXPOSE 8888

# Let runit start nginx & php-fpm
# Ensure /bin/docker-entrypoint.sh is always executed
ENTRYPOINT ["/bin/docker-entrypoint.sh"]

# Configure a healthcheck to validate that everything is up&running
#HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping || exit 1
HEALTHCHECK  CMD /bin/check.sh

