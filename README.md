# proxy-vpn
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/rooty/proxy-vpn/docker-image.yml)

Docker image that connects to an OpenVPN server and exposes an HTTP proxy (via [dumbproxy](https://github.com/SenseUnit/dumbproxy)) bound to that VPN interface. All proxy traffic exits through the VPN.

## Features

- HTTP/HTTPS proxy on port `8888` routed through OpenVPN
- Supports CONNECT method and forwarding of HTTPS connections
- Supports TLS operation mode (HTTP(S) proxy over TLS)
- Supports client authentication with client TLS certificates
- Supports HTTP/2
- Health check verifies the exit IP country matches the expected `COUNTRY` code

## Requirements

Two files must be provided at runtime:

| File | Description |
|------|-------------|
| `client.ovpn` | OpenVPN client config |
| `auth` | Credentials file (username on line 1, password on line 2) |

## Environment variables

| Variable | Required | Description |
|----------|----------|-------------|
| `COUNTRY` | Yes | Expected country code (lowercase) of the VPN exit IP, e.g. `de`, `us`. Used by the health check. |
| `PROXY_USER` | No | Proxy username. When set together with `PROXY_PASS`, enables bcrypt authentication on port 8888. |
| `PROXY_PASS` | No | Proxy password. Must be set together with `PROXY_USER`. |
| `CMD_OPTS` | No | Extra flags passed directly to `dumbproxy`. Do not use together with `PROXY_USER` and `PROXY_PASS`. |

## Usage

### auth file

```
username
password
```

### client.ovpn

```
client
dev tun
reneg-sec 0
persist-tun
persist-key
ping 5
nobind
allow-compression no
remote-random
remote-cert-tls server
auth-nocache
route-metric 1
cipher AES-256-CBC
auth sha512
<ca>
-----BEGIN CERTIFICATE-----
.......................
-----END CERTIFICATE-----
</ca>
<cert>
-----BEGIN CERTIFICATE-----
.......................
-----END CERTIFICATE-----
</cert>
<key>
-----BEGIN PRIVATE KEY-----
.......................
-----END PRIVATE KEY-----
</key>
remote server.example.com
proto udp
port 1194
```

### compose.yaml

```yaml
services:
  proxy:
    image: ghcr.io/rooty/proxy-vpn:latest
    restart: always
    privileged: true
    devices:
      - /dev/net/tun
    dns:
      - 8.8.8.8
    volumes:
      - /path/to/client.ovpn:/etc/openvpn/client.ovpn:ro
      - /path/to/auth:/etc/openvpn/auth:ro
    ports:
      - 127.0.0.1:8888:8888
    environment:
      - COUNTRY=de
      # optional: enable proxy authentication
      # - PROXY_USER=myuser
      # - PROXY_PASS=mypassword
    healthcheck:
      test: ["CMD", "check"]
      interval: 2s
      timeout: 60s
      retries: 20
    networks:
      - vpn-net

networks:
  vpn-net:
```

## How it works

1. `docker-entrypoint.sh` runs init scripts, then starts `runit`.
2. `runit` starts the OpenVPN service.
3. Once the VPN tunnel is up, OpenVPN calls `up.sh` which:
   - Adds policy-based routing so traffic from the VPN interface goes through the VPN gateway.
   - Starts `dumbproxy` bound to port `8888`, with the source IP set to the VPN interface.
4. If the VPN disconnects, `down.sh` restarts `dumbproxy` without the VPN hint (fail-safe).
5. The health check queries `ip-api.com` and verifies the returned country code matches `COUNTRY`.
