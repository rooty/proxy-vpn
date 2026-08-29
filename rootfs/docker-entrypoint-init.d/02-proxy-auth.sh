#!/bin/sh
set -e

if [ -z "$PROXY_USER" ] || [ -z "$PROXY_PASS" ]; then
    exit 0
fi

htpasswd -B -b -c /etc/dumbproxy.htpasswd "$PROXY_USER" "$PROXY_PASS"
echo "Proxy auth configured for user: $PROXY_USER"
