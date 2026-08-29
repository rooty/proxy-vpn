# Copilot Instructions for proxy-vpn

## Project Overview

`proxy-vpn` is a containerized proxy service that tunnels connections through OpenVPN. It combines OpenVPN (for VPN connectivity) and a proxy service (dumbproxy, currently disabled) in a single Alpine Linux container managed by runit.

## Architecture

The container architecture follows a service-oriented pattern:

```
┌─ Alpine Linux (base image)
├─ runit (process supervisor)
│  ├─ /etc/service/openvpn/ → OpenVPN client
│  └─ /etc/service/dumbproxy/ → Proxy server (disabled)
├─ Initialization chain
│  └─ /docker-entrypoint-init.d/ → Run startup scripts (numbered for ordering)
└─ Health checks
   └─ /bin/check.sh → Validates country via IP API
```

### Key Components

- **Entry point**: `/bin/docker-entrypoint.sh` - Orchestrates startup and graceful shutdown
- **Service management**: runit runs services from `/etc/service/*/run` scripts with supervised supervision
- **OpenVPN**: Client mode connecting to external VPN servers
- **Configuration**: External volumes mount `client.ovpn` and `auth` files at runtime
- **Health check**: Verifies proxy functionality by checking IP country code matches `COUNTRY` env var

## Build & Deploy

**Local build** (without push):
```bash
docker build -t proxy-vpn:local .
```

**CI/CD flow** (automatic on all pushes):
- GitHub Actions workflow: `.github/workflows/docker-image.yml`
- Builds and pushes to `ghcr.io/rooty/proxy-vpn:latest` plus git tags
- Requires container registry login via `GITHUB_TOKEN`
- Includes artifact attestation for supply chain security
- Runs on `ubuntu-24.04`

## Configuration & Extension

### Adding a New Service

To add a new runit-managed service (e.g., monitoring daemon):

1. Create service directory: `/rootfs/etc/service/myservice/`
2. Create executable run script: `/rootfs/etc/service/myservice/run` (typically `#!/bin/sh -e`)
3. Service will be automatically supervised by runit
4. Status checked/logged automatically in docker-entrypoint.sh

### Startup Initialization

Scripts in `/docker-entrypoint-init.d/` execute in alphanumeric order during container startup:

1. Name files with numeric prefix: `01-first.sh`, `02-second.sh`, etc.
2. Make executable (`chmod +x`)
3. Exit non-zero to fail startup
4. Example: `01-uname.sh` prints system info at startup

### Environment Variables

- `COUNTRY`: Expected country code (lowercase) for health checks (e.g., `COUNTRY=de`)
- `HEALTHCHEK_URL`: (commented out) Optional alternative health check URL
- `PROXY_USER`, `PROXY_PASS`: (commented out) For proxy authentication

### Container Runtime Requirements

- `privileged: true` - Required for TUN device access
- `devices: [/dev/net/tun]` - TUN device for VPN
- Custom DNS: Typically `8.8.8.8`
- Volume mounts (read-only):
  - `/path/to/client.ovpn:/etc/openvpn/client.ovpn:ro`
  - `/path/to/auth:/etc/openvpn/auth:ro`

## Common Patterns

### Signal Handling

The entrypoint gracefully handles `SIGTERM`, `SIGHUP`, `SIGQUIT`, `SIGINT`:
- Stops all runit services via `sv force-stop`
- Waits for process cleanup
- Kills remaining PIDs with escalating signals (TERM → KILL)

### Configuration Templating

The container uses `envsubst` for dynamic configuration:
- Included in Dockerfile for template expansion
- Useful for injecting environment variables into config files

### Health Check Pattern

Current health check (`/bin/check.sh`):
```bash
curl http://ip-api.com/json | jq '.countryCode' | grep -i $COUNTRY
```
- Validates proxy is working by checking visible country matches configuration
- Returns exit 0 (success) or 1 (failure)

## File Structure Reference

```
rootfs/
├── bin/
│   ├── docker-entrypoint.sh    # Startup and supervision orchestrator
│   └── check.sh                # Health check script
├── etc/
│   ├── openvpn/
│   │   ├── client.conf         # OpenVPN client configuration
│   │   ├── up.sh               # Interface up hook
│   │   ├── down.sh             # Interface down hook
│   │   └── update-resolv-conf  # DNS update helper
│   ├── iproute2/rt_tables      # Routing tables
│   ├── service/
│   │   ├── openvpn/run         # OpenVPN runit service
│   │   └── dumbproxy/run       # Proxy service (disabled)
│   └── docker-entrypoint-init.d/
│       └── 01-uname.sh         # Example initialization script
```

## Important Notes

- **dumbproxy service is currently disabled** - The run script is commented out; enable by uncommenting
- **Shell scripts require `#!/bin/sh` or `#!/bin/bash`** with executable permissions
- **Environment variable leakage prevention** - runit services use `env -` to clear env vars before execution
- **No package manager after build** - APK cache is cleaned to minimize image size
- **Error handling** - Initialization scripts must exit 0 on success; non-zero exits fail container startup
