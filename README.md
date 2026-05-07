# Prismbox

**Prismbox** is a self-hostable photo and video management platform. This repository contains a production-oriented **Go backend** (REST API, authentication, albums, media, sharing) and a **Flutter mobile client**.

[中文说明](README.zh-CN.md)

## Overview

- **Backend (`backend/`)**: Go (Gin + GORM), PostgreSQL, and a containerized stack with Nginx as reverse proxy; optional distributed job processing via the in-repo **GQ (Go-Gorm-Queue)** framework.
- **Mobile (`mobile/`)**: Flutter application for iOS and Android that connects to your self-hosted API.

For backend capabilities, architecture, and module documentation, see [`backend/README.md`](backend/README.md) and [`backend/doc/INDEX.md`](backend/doc/INDEX.md).

## Repository layout

| Path         | Description                                                |
| ------------ | ---------------------------------------------------------- |
| `backend/`   | API server, Docker/Compose deployment, operations scripts  |
| `mobile/`    | Flutter client                                             |
| `openspec/`  | OpenSpec and project specifications (when applicable)    |

## Deploy the backend to your private cloud

These paths are for **your own infrastructure** (VPC, on-premises, or a private registry). The stack is **Docker-native** and avoids vendor-specific hosting.

### Prerequisites

- Docker **20.10+** and Docker Compose **v2** (`docker compose`)
- Recommended baseline: **≥ 2 GB** RAM and **≥ 10 GB** disk for a small deployment (scale storage for media)

### Option A — Remote one-liner (no `git clone`)

On a host with Docker, run from the directory that should become the install root:

```bash
curl -fsSL https://raw.githubusercontent.com/skyline93/prismbox/main/backend/scripts/install.sh | sh
```

Non-interactive install, custom directory, and HTTPS Compose profile (see the deployment guide for certificates and DNS):

```bash
curl -fsSL https://raw.githubusercontent.com/skyline93/prismbox/main/backend/scripts/install.sh | sh -s -- --dir /opt/prismbox-backend --yes --https
```

**Private Git or air-gapped mirrors:** set `PRISMBOX_GIT_HOST`, `PRISMBOX_REPO`, and related variables so the installer fetches `docker-compose` and scripts from your host (see comments at the top of `backend/scripts/install.sh`). Pin a release with `PRISMBOX_REF` for reproducible deploys.

### Option B — Clone the repository and deploy

```bash
git clone https://github.com/skyline93/prismbox.git
cd prismbox/backend
./deploy.sh
```

You can also use Make targets such as `make deploy`; details are in [`backend/doc/DEPLOYMENT/README.md`](backend/doc/DEPLOYMENT/README.md).

### Next steps

- Operations, HTTPS (self-signed vs Let’s Encrypt), environment variables, upgrades, and troubleshooting: **[Deployment guide](backend/doc/DEPLOYMENT/README.md)**
- Architecture: [`backend/doc/ARCHITECTURE/README.md`](backend/doc/ARCHITECTURE/README.md)

## Mobile client

Configure the app to use your backend’s URL (public or VPN). Getting started: [`mobile/README.md`](mobile/README.md).

## Contributing

Issues and pull requests are welcome. For larger changes, follow project conventions under `openspec/` and [`AGENTS.md`](AGENTS.md) when applicable.

## License

[MIT](LICENSE)
