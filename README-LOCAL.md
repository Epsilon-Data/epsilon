# Run Locally (Full Platform, No Hardware Required)

Run the entire Epsilon Trusted Research Environment on your machine using Docker Compose in simulation mode. All services use pre-built Docker images from GitHub Container Registry — no source code compilation needed.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          EPSILON PLATFORM                              │
│                                                                        │
│  ┌──────────┐  ┌──────────┐  ┌─────────────┐  ┌──────────────────┐    │
│  │ Frontend │  │   API    │  │Job Scheduler│  │  Trust Hub    │    │
│  │ :3000    │  │ :3334    │  │   :3005     │  │     :3001        │    │
│  └────┬─────┘  └────┬─────┘  └──────┬──────┘  └────────┬─────────┘    │
│       │              │               │                  │              │
│  ┌────┴─────┐  ┌─────┴──────┐  ┌────┴──────────────────┴───────┐      │
│  │  Token   │  │ Middleware │  │        Coordinator             │      │
│  │ Handler  │  │   :8001    │  │  Fetcher → Clone → AI Agent   │      │
│  │  :8081   │  └─────┬──────┘  │           → Executor          │      │
│  └──────────┘        │         └───────────────────────────────┘      │
│                      │                                                │
│  ┌───────────────────┴────────────────────────────────────────────┐   │
│  │                    INFRASTRUCTURE                              │   │
│  │  PostgreSQL (×4)  │  Keycloak  │  Vault  │  Redis             │   │
│  │  Atlas + Cassandra + Elasticsearch + Kafka + Zookeeper        │   │
│  └───────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

### How Data Flows

1. **Data Owner** registers their database via the Frontend → API crawls schema via **data-broker** → metadata stored in **Atlas**
2. **Researcher** requests access to a dataset → Data Owner approves (or auto-approved if public)
3. **Researcher** writes analysis code using the Epsilon SDK → pushes to GitHub
4. **Researcher** submits a job via the Job Scheduler
5. **Coordinator** pipeline processes the job:
   - **Fetcher** picks up queued jobs from the scheduler database
   - **Clone** clones the researcher's GitHub repository
   - **AI Agent** (optional) analyzes the code for PII leaks and policy violations using CrewAI — requires `OPENAI_API_KEY` in `.env` (jobs skip AI analysis if unset)
   - **Executor** fetches encrypted data via **Middleware** → runs the analysis in a simulated enclave → generates a cryptographic attestation document
6. **Trust Hub** displays the attestation for independent client-side verification

### Key Design Principle

Data **never leaves the data owner's database** in raw form. The Middleware fetches it, encrypts it, and sends it to the enclave (or local simulator). The platform operator never sees raw data. Output is bound to an attestation document with SHA-256 hashes of the script, dataset, and result.

## Important Notes

> **Rathole is NOT required for local deployment.** Rathole is only used with "Epsilon Proxy" mode (source-side encryption for BYOD). The local deployment uses "Cloud Connect" mode, where the platform connects to your database directly via the middleware service. No tunnel or rathole configuration needed. If you see rathole in a restarting state, it can be safely ignored.

> **epsilon-proxy is NOT required for local deployment.** In local mode, select "Cloud Connect" when creating a project. The platform connects to your database directly. epsilon-proxy is only needed for production BYOD with source-side encryption.

## Prerequisites

- **Docker & Docker Compose v2** (Docker Desktop 4.x recommended)
- **16 GB RAM** recommended (8 GB minimum)
- **Required ports**: 3000, 3001, 3005, 3334, 5432, 6379, 8001, 8080, 8081, 8200, 9042, 9092, 9200, 21000
- Add to `/etc/hosts`:
  ```
  127.0.0.1 keycloak
  ```

## Quick Start

```bash
git clone https://github.com/Epsilon-Data/epsilon.git
cd epsilon
make setup    # copy .env.example → .env
make infra    # start infrastructure (databases, Keycloak, Atlas, etc.)
make migrate  # run database migrations
make apps     # start application services
make check    # verify everything is healthy
```

> **First boot takes ~20-30 minutes.** This is normal and only happens once. Docker pulls ~10 GB of images, and Atlas initializes its JanusGraph schema on Cassandra + Elasticsearch — this is the slowest part. You can monitor Atlas progress at http://localhost:21000. Subsequent runs start in under 2 minutes since all data persists in Docker volumes.

### GitHub OAuth (required for job submission)

Researchers submit jobs from GitHub repositories. You need a GitHub OAuth app:

1. Go to https://github.com/settings/developers → **New OAuth App**
2. Set **Homepage URL**: `http://localhost:3005`, **Callback URL**: `http://localhost:3005/api/github/callback`
3. Add `GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET` to `.env`
4. If services are already running:
   ```bash
   docker compose restart job-scheduler
   ```

## Services & URLs

| Service | URL | Description |
|---------|-----|-------------|
| Frontend (Data Hub) | http://localhost:3000 | Dataset management, archetype builder |
| Job Scheduler | http://localhost:3005 | Research workspace, job submission |
| Trust Hub | http://localhost:3001 | Attestation verification |
| API | http://localhost:3334 | NestJS backend |
| Keycloak | http://localhost:8080 | Identity provider (admin: `admin@epsilon-data.org` / `secret`) |
| Vault | http://localhost:8200 | Secrets management |
| Atlas | http://localhost:21000 | Metadata catalog (admin: `admin` / `secret`) |

## Full Pipeline Walkthrough

### 1. Create a Dataset (Data Owner)

#### Setting up a test database (if you don't have one)

If you don't have a PostgreSQL database to test with, use the included seed script:

```bash
# 1. Create and seed the sample database on the platform's PostgreSQL
docker exec -i pg_platform psql -U epsilon_admin -d epsilon -c "CREATE DATABASE epsilon_sample"
docker exec -i pg_platform psql -U epsilon_admin -d epsilon_sample < scripts/seed-sample-db.sql

# 2. Verify
docker exec pg_platform psql -U epsilon_admin -d epsilon_sample -c "\
  SELECT 'university' AS table, count(*) FROM university UNION ALL \
  SELECT 'student', count(*) FROM student UNION ALL \
  SELECT 'subject', count(*) FROM subject UNION ALL \
  SELECT 'student_subject', count(*) FROM student_subject;"
```

This creates an `epsilon_sample` database with 4 tables (5 universities, 50 students, 23 subjects, 64 enrollments) on the platform's PostgreSQL.

Alternatively, use any existing PostgreSQL database accessible from Docker (e.g. local PostgreSQL, cloud-hosted, etc.).

#### Creating the dataset

1. Open http://localhost:3000
2. Log in as **Data Owner**: `owner@epsilon-data.org` / `secret`
3. Create a new project
4. When asked **"How should the platform access your data?"**, choose **Cloud Connect** (not Epsilon Proxy — proxy is for production BYOD setups, not local dev)
5. Enter database credentials using either option:

   **Option A — Database URL:**
   ```
   postgresql://epsilon_admin:supersecret@pg_platform:5432/epsilon_sample
   ```

   **Option B — Manual entry:**

| Field | Value |
|-------|-------|
| Hostname | `pg_platform` |
| Port | `5432` |
| Username | `epsilon_admin` |
| Password | `supersecret` |
| Database | `epsilon_sample` |
| SSL | Off |

> **Note**: Use `pg_platform` as hostname — the API and data-broker connect to it via Docker's internal network.

6. Wait for the data broker to crawl the schema (~30s). You can check progress with `docker logs data-broker-* -f`
7. Click **Create Archetype** — select which tables and columns to expose in the tree view
8. Click **Publish** — the dataset is now visible to researchers in Browse Hub

### 2. Request Access to a Dataset (Researcher)

1. Open http://localhost:3000
2. Log in as **Researcher**: `researcher@epsilon-data.org` / `secret`
3. Go to **Browse Hub** → **Browse Projects** to see published datasets
4. Click on a dataset and send a **Connection Request**
   - **Public datasets** are auto-approved
   - **Private datasets** require the Data Owner to approve the request
5. Check your request status at **Browse Hub → Track Requests**
6. Once approved, the researcher has access to the dataset ID and archetype ID

### 3. Prepare a Research Repository

1. Fork or use the [epsilon-research-template](https://github.com/Epsilon-Data/epsilon-research-template) as a template on GitHub
2. Install the Epsilon SDK and initialize:
   ```bash
   pip install epsilon-sdk
   epsilon change-server http://localhost:3334    # Point to local instance
   epsilon login                                   # Authenticate (researcher@epsilon-data.org / secret)
   epsilon datasets                                # Lists all datasets you have access to, with IDs
   epsilon init <dataset_id>                       # Generates project.yml, main.py, generated/
   ```
3. Edit `main.py` with your analysis code
4. Test locally: `epsilon run` (runs against synthetic data)
5. Build for deployment: `epsilon build` (creates `build/` directory)
6. Push your code to GitHub

### 4. Submit a Research Job

1. Open http://localhost:3005
2. Log in as **Researcher**: `researcher@epsilon-data.org` / `secret`
3. Connect your GitHub account (requires GitHub OAuth setup)
4. Create a workspace pointing to your research repository
5. Submit a job — the coordinator pipeline processes it:

```
  ┌─────────┐    ┌─────────┐    ┌───────────┐    ┌─────────┐
  │ Fetcher │───▶│  Clone  │───▶│ Executor  │───▶│ Success │
  │ queued  │    │ cloned  │    │ executing │    │         │
  └─────────┘    └────┬────┘    └─────┬─────┘    └─────────┘
                      │               │
                      ▼               ▼
                ┌──────────┐   ┌─────────────┐
                │ AI Agent │   │ Fetch data  │
                │(parallel,│   │ Encrypt     │
                │ optional)│   │ Execute     │
                └──────────┘   │ Attest      │
                               └─────────────┘
```

6. View the job detail page — shows execution output, attestation document, PCR values, script/dataset/output hashes, execution metrics, and server verification results


## Test Accounts

| Role | Email | Password | Use |
|------|-------|----------|-----|
| Data Owner | `owner@epsilon-data.org` | `secret` | Create datasets, manage archetypes |
| Researcher | `researcher@epsilon-data.org` | `secret` | Request access, submit jobs |
| DB Admin | `dbadmin@epsilon-data.org` | `secret` | Database administration |
| Keycloak Admin | `admin@epsilon-data.org` | `secret` | Identity provider admin |

## Local Simulation Mode

The platform runs in **simulation mode** by default:

- `USE_LOCAL_ENCLAVE=true` — enclave logic runs as a regular Python process (no AWS Nitro hardware needed)
- Attestation documents are **structurally identical** COSE_Sign1 documents signed by a local ECDSA P-384 CA
- The Trust Hub's client-side verifier (`@epsilon-data/nitro-verify`) accepts the local root CA via `DEV_MODE=true`
- PCR values are placeholders — real hardware measurements only exist in production with AWS Nitro Enclaves
- All other functionality (archetype builder, job pipeline, data ingestion, verification) works identically to production

## Docker Images

All application services use pre-built images from GitHub Container Registry:

| Service | Image | Source Repo |
|---------|-------|-------------|
| API | `ghcr.io/epsilon-data/api` | [Epsilon-Data/api](https://github.com/Epsilon-Data/api) |
| Frontend | `ghcr.io/epsilon-data/frontend` | [Epsilon-Data/frontend](https://github.com/Epsilon-Data/frontend) |
| Job Scheduler | `ghcr.io/epsilon-data/job-scheduler` | [Epsilon-Data/job-scheduler](https://github.com/Epsilon-Data/job-scheduler) |
| Middleware | `ghcr.io/epsilon-data/epsilon-middleware` | [Epsilon-Data/epsilon-middleware](https://github.com/Epsilon-Data/epsilon-middleware) |
| Coordinator | `ghcr.io/epsilon-data/coordinator` | [Epsilon-Data/coordinator](https://github.com/Epsilon-Data/coordinator) |
| Trust Hub | `ghcr.io/epsilon-data/epsilon-trust-center` | [Epsilon-Data/epsilon-trust-center](https://github.com/Epsilon-Data/epsilon-trust-center) |
| Token Handler | `ghcr.io/epsilon-data/ts-services` | [Epsilon-Data/ts-packages](https://github.com/Epsilon-Data/ts-packages) |

## Commands

```bash
# Full startup (recommended for first run)
make infra      # 1. Start infrastructure (databases, Keycloak, Vault, Atlas, etc.)
make migrate    # 2. Run database migrations
make apps       # 3. Start application services one by one
make check      # 4. Verify all services are healthy

# Or all at once
make up         # Runs infra → migrate → apps automatically

# Lifecycle
make down       # Stop everything (keeps data)
make restart    # Stop + start
make clean      # Stop and delete all data (volumes)

# Monitoring
make check      # Verify all services
make status     # Show container status
make logs       # Follow all logs

# Individual restarts
make restart-api           # Restart API only
make restart-frontend      # Restart frontend only
make restart-atlas         # Restart Atlas metadata server
make restart-coordinator   # Restart all coordinator workers
make restart-scheduler     # Restart job scheduler
make restart-trust-center  # Restart trust center
make fix-networks          # Fix Docker network issues (restarts key services)
```

## Troubleshooting

### Port already in use

If `make up` fails with `Ports are not available: ... address already in use`:

```bash
# 1. Stop all containers
make down

# 2. Force-remove any leftover containers
docker rm -f $(docker ps -aq) 2>/dev/null

# 3. If ports are STILL held (common on Mac after failed starts):
#    Quit Docker Desktop completely (not just close window),
#    wait 5 seconds, reopen it, then:
make up
```

To check which ports are stuck: `lsof -i :<port> | grep LISTEN`

### `make up` fails at health check (first run)

On the very first run, Keycloak and Cassandra need extra time to initialize. If `make up` fails with `dependency failed to start: container X is unhealthy`, just run `make up` again — Docker will resume from where it left off (volumes persist).

### Atlas takes too long

Normal on first boot — Atlas initializes JanusGraph + Cassandra + Elasticsearch backends. Check http://localhost:21000 for status. Takes several minutes on first run, under 30 seconds on subsequent runs.

### "Metadata service unavailable" or Atlas errors

If the API can't reach Atlas (`getaddrinfo ENOTFOUND atlas-server`), run:

```bash
make fix-networks
```

This reconnects any dropped Docker networks and restarts the API.

### Keycloak "HTTPS required" error

If you see an HTTPS redirect error when logging in locally:

```bash
docker exec keycloak /opt/keycloak/bin/kcadm.sh config credentials \
  --server http://localhost:8080 --realm master \
  --user admin@epsilon-data.org --password secret

docker exec keycloak /opt/keycloak/bin/kcadm.sh update realms/epsilon -s sslRequired=NONE
```

### Other issues

| Issue | Fix |
|-------|-----|
| `keycloak` hostname not resolved | Ensure `127.0.0.1 keycloak` is in `/etc/hosts` |
| Data broker fails to crawl | Ensure Atlas is healthy (`docker logs atlas-server`) and the database is reachable |
| Middleware returns 401 | Check `EPSILON_CLIENT_ID` and `EPSILON_CLIENT_SECRET` match Keycloak's `coordinator-client` |
| Windows | Requires WSL2 with Docker Desktop. The Makefile uses bash — run from WSL2 terminal |
