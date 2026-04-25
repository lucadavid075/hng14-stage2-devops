# hng14-stage2-devops - Job Processor — Containerized Microservices

A production-ready job processing system composed of four services orchestrated with Docker Compose, with a full CI/CD pipeline on GitHub Actions.

```
frontend (Node.js/Express) ──► api (Python/FastAPI) ──► redis (queue)
                                                              │
                                          worker (Python) ◄──┘
```

---

## Prerequisites

| Tool | Minimum version | Install |
|------|-----------------|---------|
| Docker | 24.x | https://docs.docker.com/get-docker/ |
| Docker Compose | v2.20+ (bundled with Docker Desktop) | — |
| Git | 2.x | https://git-scm.com |

No cloud account is required. Everything runs locally.

---

## Quickstart — bring the stack up from scratch

### 1. Clone the repository

```bash
git clone https://github.com/lucadavid075/hng14-stage2-devops.git
cd hng14-stage2-devops
```

### 2. Create your `.env` file

```bash
cp .env.example .env
```

Open `.env` and set a strong Redis password:

```dotenv
REDIS_PASSWORD=your_redis_password_here
APP_ENV=production
FRONTEND_PORT=3000
REGISTRY=local
TAG=latest
```

> **Warning:** Never commit `.env` to git. It is listed in `.gitignore`.

### 3. Build and start all services

```bash
docker compose up --build -d
```

This will:
- Build the `api`, `worker`, and `frontend` images from their Dockerfiles
- Pull the official `redis:7.2-alpine` image
- Start all four containers on an internal Docker network
- Wait for Redis to be healthy before starting the API and worker
- Wait for the API to be healthy before starting the frontend

### 4. Verify a successful startup

```bash
docker compose ps
```

Expected output — all services should show `healthy`:

```
NAME                      STATUS              PORTS
jobprocessor-redis-1      Up (healthy)        6379/tcp
jobprocessor-api-1        Up (healthy)        8000/tcp
jobprocessor-worker-1     Up (healthy)
jobprocessor-frontend-1   Up (healthy)        0.0.0.0:3000->3000/tcp
```

Open your browser at **http://localhost:3000**. Click **Submit New Job** — the job ID appears and updates to `completed` within a few seconds.

### 5. Check service logs

```bash
docker compose logs -f          # all services
docker compose logs -f api      # API only
docker compose logs -f worker   # worker only
```

### 6. Tear down

```bash
docker compose down           # stop containers, keep volumes
docker compose down -v        # stop containers AND delete Redis data
```

---

## Architecture

| Service | Port (internal) | Host port | Description |
|---------|-----------------|-----------|-------------|
| `redis` | 6379 | not exposed | Job queue and status store |
| `api` | 8000 | not exposed | FastAPI — creates jobs, returns status |
| `worker` | — | — | Picks jobs from queue, marks completed |
| `frontend` | 3000 | 3000 (configurable) | Express — UI + proxy to API |

All services communicate over a named Docker bridge network (`internal`). Redis is not exposed on the host. Only the frontend port is published.

---

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `REDIS_PASSWORD` | **Yes** | — | Password for Redis `requirepass` |
| `FRONTEND_PORT` | No | `3000` | Host port to expose the frontend on |
| `REGISTRY` | No | `local` | Image registry prefix |
| `TAG` | No | `latest` | Image tag |

---

## CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/ci.yml`) runs on every push and PR:

```
lint → test → build → security scan → integration test → deploy*
```

\* Deploy runs only on pushes to `main`.

| Stage | What it does |
|-------|-------------|
| **lint** | `flake8` (Python), `eslint` (JS), `hadolint` (Dockerfiles) |
| **test** | `pytest` with Redis mocked, coverage report uploaded as artifact |
| **build** | Builds all 3 images, pushes to ephemeral local registry (per task spec) + saves tarballs as artifacts; pushes to GHCR on `main` |
| **security** | Trivy scans all images; fails pipeline on any `CRITICAL` CVE; uploads SARIF |
| **integration** | Loads images, starts full stack, submits a job, polls until `completed`, tears down |
| **deploy** | SSH rolling update: new container must pass health check within 60s or old one is kept |

A failure in any stage prevents all subsequent stages from running.

---

## Running Tests Locally

```bash
cd api
pip install -r requirements.txt -r requirements-dev.txt
pytest tests/ --cov=. --cov-report=term-missing -v
```

---

## Project Structure

```
.
├── api/
│   ├── Dockerfile
│   ├── main.py
│   ├── requirements.txt
│   ├── requirements-dev.txt
│   └── tests/
│       └── test_main.py
├── worker/
│   ├── Dockerfile
│   ├── worker.py
│   └── requirements.txt
├── frontend/
│   ├── Dockerfile
│   ├── app.js
│   ├── package.json
│   ├── package-lock.json
│   ├── .eslintrc.json
│   └── views/
│       └── index.html
├── .github/
│   └── workflows/
│       └── ci.yml
├── docker-compose.yml
├── .env.example
├── .gitignore
├── FIXES.md
└── README.md
```
