# Repository Guidelines

## Project Structure & Module Organization

This repository builds an Alpine-based container that routes a `dumbproxy` HTTP(S) proxy through OpenVPN. Treat `rootfs/` as the main application surface.

- `Dockerfile` installs runtime packages, downloads `dumbproxy`, and copies the container filesystem.
- `compose.yaml` provides a local runtime example with TUN access, VPN credentials, port `8888`, and health checks.
- `rootfs/bin/` contains startup, healthcheck, and service orchestration scripts.
- `rootfs/etc/openvpn/` contains OpenVPN client configuration and route/DNS hook scripts.
- `rootfs/etc/service/` contains `runit` service launch scripts.
- `.github/workflows/docker-image.yml` builds and publishes the image to GHCR.
- `README.md` documents the required `client.ovpn` and `auth` files.

Keep files near their in-container destination; for example, a new executable intended for `/bin` belongs under `rootfs/bin/`.

## Build, Test, and Development Commands

- `docker build -t proxy-vpn:local .` builds the image locally.
- `docker compose config` validates Compose syntax and interpolation.
- `docker compose up --build proxy-de` builds and starts the sample service. Replace placeholder volume paths in `compose.yaml` first.
- `docker compose logs -f proxy-de` follows OpenVPN, runit, and proxy startup output.
- `docker inspect --format '{{json .State.Health}}' <container>` checks the image health probe.
- `docker run --rm --privileged --device /dev/net/tun proxy-vpn:local` smoke-tests startup when the VPN configuration is available.

Use Docker BuildKit when matching CI behavior: `DOCKER_BUILDKIT=1 docker build -t proxy-vpn:local .`.

## Coding Style & Naming Conventions

Shell is the primary implementation language. Preserve the interpreter already used by each file (`/bin/sh` or Bash), use two-space indentation for new shell blocks, quote variable expansions, and keep environment-variable names uppercase such as `COUNTRY` and `CMD_OPTS`. Name lifecycle scripts by purpose (for example, `up.sh`, `down.sh`, and `check.sh`). Use two-space YAML indentation and lowercase, hyphenated service names.

Dockerfile changes should preserve small image size: use `apk --no-cache`, remove build-only packages, and keep cache cleanup. Prefer lowercase environment values where checks expect them; for example, `COUNTRY=de`. Keep runtime scripts executable, and name init scripts with numeric prefixes such as `01-uname.sh`.

## Testing Guidelines

There is no automated unit-test framework. Validate changes with:

- `docker build -t proxy-vpn:local .`
- `docker compose config`
- A container startup check when runtime changes touch `rootfs/bin/`, `rootfs/etc/service/`, or OpenVPN hooks.
- For healthcheck edits, verify `/bin/check.sh` with both expected and failed `COUNTRY` matches.

Before submitting changes, start the container with test VPN credentials and confirm the container becomes healthy. For routing changes, verify the public IP/country through the proxy on port `8888` and inspect `ip route` and `ip rule` inside the container.

## Commit & Pull Request Guidelines

Recent history uses short, imperative, lowercase subjects such as `fix route table` and `add down script`. Keep commits focused and describe the observable change. Pull requests should explain the motivation, list validation commands, call out networking or security implications, and link relevant issues. Include logs or configuration excerpts when behavior changes; never commit VPN credentials, private keys, or real provider profiles.

## Security & Configuration Tips

Do not commit real VPN credentials, private keys, certificates, or proxy passwords. Mount `client.ovpn` and `auth` read-only at runtime. Be careful with `privileged: true`, `/dev/net/tun`, DNS, and routing scripts because small changes can alter network behavior.
