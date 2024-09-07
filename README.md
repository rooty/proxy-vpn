# proxy-vpn
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/rooty/proxy-vpn/docker-image.yml)

Для запуска OpenVPN необходимо подготовить 2 файла
- auth в котором сохранены login/password 

пример password file
```
login
pasword
```
- и файл подключения к удаленному серверу VPN

пример client.ovpn file
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

Пример docker-compose.yml файла
```yaml
services:
  proxy-de:
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


