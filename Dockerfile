# syntax=docker/dockerfile:1
FROM alpine:latest

LABEL org.opencontainers.image.source="https://github.com/rooty/proxy-vpn"
LABEL org.opencontainers.image.description="OpenVPN+Proxy"
LABEL org.opencontainers.image.licenses=MIT

# Install packages
RUN apk --no-cache add \
        runit \
        curl \
        openvpn \
        tinyproxy \
        bash \
        jq \
# Bring in gettext so we can get `envsubst`, then throw
# the rest away. To do this, we need to install `gettext`
# then move `envsubst` out of the way so `gettext` can
# be deleted completely, then move `envsubst` back.
    && apk add --no-cache --virtual .gettext gettext \
    && mv /usr/bin/envsubst /tmp/ \
    && runDeps="$( \
        scanelf --needed --nobanner /tmp/envsubst \
            | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            | sort -u \
            | xargs -r apk info --installed \
            | sort -u \
    )" \
    && apk add --no-cache $runDeps \
    && apk del .gettext \
    && mv /tmp/envsubst /usr/local/bin/ \
# Remove alpine cache
    && rm -rf /var/cache/apk/* 
    # \
# Make sure files/folders needed by the processes are accessable when they run under the nobody user
    # && chown -R nobody.nobody /run 
RUN curl -L  -qs  https://github.com/SenseUnit/dumbproxy/releases/download/v1.12.0/dumbproxy.linux-amd64 --output  /usr/local/bin/dumbproxy && chmod +x /usr/local/bin/dumbproxy 

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

