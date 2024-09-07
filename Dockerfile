# syntax=docker/dockerfile:1

#LABEL MAINTAINER Vitaliy Mikhnevych blackrooty@gmail.com

#FROM alpine:latest
FROM alpine:3.20.2

# Install packages
RUN apk --no-cache add \
        runit \
        curl \
        openvpn \
        tinyproxy \
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
    && rm -rf /var/cache/apk/* \
# Make sure files/folders needed by the processes are accessable when they run under the nobody user
    && chown -R nobody.nobody /run 

# Add configuration files
COPY --chown=nobody rootfs/ /

# Switch to use a non-root user from here on
#USER nobody

# Add application
WORKDIR /etc/openvpn

# Expose the port nginx is reachable on
EXPOSE 8888

# Let runit start nginx & php-fpm
# Ensure /bin/docker-entrypoint.sh is always executed
ENTRYPOINT ["/bin/docker-entrypoint.sh"]


# Configure a healthcheck to validate that everything is up&running
#HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping || exit 1

