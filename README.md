# proxy-vpn
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/rooty/proxy-vpn/docker-image.yml)

## Features

- Supports CONNECT method and forwarding of HTTPS connections
- Supports TLS operation mode (HTTP(S) proxy over TLS)
- Supports client authentication with client TLS certificates
- Supports HTTP/2

## Usage
For run OpenVPN prepare 2 files
- login/password file: auth
- client VPN config: client.ovpn


### Example auth file
```
login
pasword
```

### Example  client.ovpn file
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
.......................
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
.......................
.......................
-----END CERTIFICATE-----
</ca>
<cert>

-----BEGIN CERTIFICATE-----
.......................
.......................
-----END CERTIFICATE-----
</cert>
<key>
-----BEGIN PRIVATE KEY-----
.......................
.......................
-----END PRIVATE KEY-----

</key>
remote server.example.com
proto udp

port 1194
```
### Exmaple compose.yaml file
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
        - '/path/to/file.ovpn':/etc/openvpn/client.ovpn:ro
        - '/path/to/file.auth':/etc/openvpn/auth:ro
    ports:
       - 127.0.0.1:8888:8888
    networks:
         - vpn-net
```


