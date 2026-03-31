# Epsilon

**A Bring-Your-Own-Data Research Platform with Trusted Verification**

Epsilon is an open-source platform for analyzing sensitive research data with per-execution verification using AWS Nitro Enclaves. Researchers link their own datasets without uploading data to platform infrastructure, and receive TEE-signed verification receipts binding specific code to specific data.

> SysTEX 2026 — 9th Workshop on System Software for Trusted Execution

## Quick Check (5 minutes)

Verify a real AWS Nitro attestation without any platform setup:

```bash
# JavaScript
npm install @epsilon-data/nitro-verify && node verify-example.mjs

# Python
pip install epsilon-attestation-verifier && python verify-example.py
```

Then explore the live platform: https://app.epsilon-data.org (login: `reviewer1@epsilon-data.org` / `secret12345`)

## Artifact Scope

| Component | Provided |
|-----------|----------|
| Live production instance (real Nitro Enclaves) | [app.epsilon-data.org](https://app.epsilon-data.org) |
| Local Docker deployment (31 containers) | `make up` |
| npm package (client-side attestation verifier) | [@epsilon-data/nitro-verify](https://www.npmjs.com/package/@epsilon-data/nitro-verify) |
| PyPI package (Python attestation verifier) | [epsilon-attestation-verifier](https://pypi.org/project/epsilon-attestation-verifier/) |
| PyPI package (researcher SDK) | [epsilon-sdk](https://pypi.org/project/epsilon-sdk/) |
| Go CLI (source-side encryption proxy) | [epsilon-proxy](https://github.com/Epsilon-Data/epsilon-proxy) |
| Source code (10 repositories) | [github.com/Epsilon-Data](https://github.com/Epsilon-Data) |
| Pre-configured test accounts | 5 reviewer accounts |
| Step-by-step GIF walkthrough | 7 GIFs in production guide |

## Getting Started

Choose one of two evaluation paths:

| | Option | Best For | Time |
|---|--------|----------|------|
| A | [Try on Production](README-PRODUCTION.md) | Quick evaluation, no setup | ~10 min |
| B | [Run Locally](README-LOCAL.md) | Full source inspection, offline | ~30 min |

## Architecture

```
  DATA OWNER'S MACHINE                         AWS CLOUD
 ┌─────────────────────┐        ┌─────────────────────────────────────────────┐
 │ ┌─────────────────┐ │        │           Frontend (:3000)                  │
 │ │   PostgreSQL DB  │ │        │           React + TypeScript                │
 │ └────────┬────────┘ │        └──────────────────┬──────────────────────────┘
 │          │          │                           │
 │ ┌────────▼────────┐ │               ┌───────────┼───────────┐
 │ │  epsilon-proxy   │ │               ▼           ▼           ▼
 │ │  (Go binary)     │ │        ┌──────────┐ ┌────────┐ ┌────────────┐
 │ │  • verify attest │ │        │ API      │ │Keycloak│ │Job Sched.  │
 │ │  • encrypt data  │ │        │ (:3334)  │ │(:8080) │ │(:3005)     │
 │ └────────┬────────┘ │        └─────┬────┘ └────────┘ └────────────┘
 │          │          │              │
 │  ┌───────▼───────┐  │       ┌──────┴───────┐
 │  │rathole client │──┼──────►│  Coordinator  │◄── AI Agent (outside TCB)
 │  └───────────────┘  │ tunnel│  (4 workers)  │
 └─────────────────────┘       └──────┬────────┘
   credentials never leave             │ vsock
   this machine                 ┌──────▼──────────┐
                                │  Nitro Enclave   │
   plaintext never leaves       │  • decrypt data  │
   proxy + enclave              │  • execute code  │
                                │  • attestation   │
                                └──────┬──────────┘
                                       │
                                ┌──────▼──────────┐
                                │  Trust Center    │
                                │  (:3001)         │
                                │  client-side     │
                                │  verification    │
                                └─────────────────┘
```

> **Key principle:** No platform component sees plaintext data. The proxy encrypts at the data source; only the enclave can decrypt. See [coordinator architecture](https://github.com/Epsilon-Data/coordinator#detailed-architecture) for detailed sequence diagrams.

## Repository Structure

This is the main orchestration repo. Component source code lives in sibling directories:

| Component | Repo | Description |
|-----------|------|-------------|
| API | [api](https://github.com/Epsilon-Data/api) | NestJS backend — datasets, archetypes, jobs |
| Frontend | [frontend](https://github.com/Epsilon-Data/frontend) | React UI — Data Hub, archetype builder |
| Coordinator | [coordinator](https://github.com/Epsilon-Data/coordinator) | Python workers — job fetcher, clone, AI agent, executor ([detailed architecture](https://github.com/Epsilon-Data/coordinator#detailed-architecture)) |
| Enclave | [epsilon-enclave](https://github.com/Epsilon-Data/epsilon-enclave) | Python TEE runtime — encryption, execution, attestation |
| Trust Center | [epsilon-trust-center](https://github.com/Epsilon-Data/epsilon-trust-center) | Verification Center — public attestation viewer |
| Job Scheduler | [job-scheduler](https://github.com/Epsilon-Data/job-scheduler) | Research workspace — job submission UI |
| SDK | [epsilon-sdk](https://github.com/Epsilon-Data/epsilon-sdk) | Python CLI — `epsilon init/run/build` |
| Proxy | [epsilon-proxy](https://github.com/Epsilon-Data/epsilon-proxy) | Go binary — source-side encryption for BYOD |
| Nitro Verify | [nitro-verify](https://github.com/Epsilon-Data/nitro-verify) | TypeScript — client-side attestation verifier |
| Research Template | [epsilon-research-template](https://github.com/Epsilon-Data/epsilon-research-template) | Starter project for researchers |

## Commands

```bash
make help         # show all commands
make setup        # first-time setup
make up           # start everything
make down         # stop everything
make logs         # follow all logs
make status       # check service health
make check        # verify all services are running and healthy
make clean        # stop and delete all data
make infra        # start infrastructure only
make apps         # start apps only (after infra is healthy)
```

## Published Packages

### Standalone Verifiers (no platform required)

These packages verify **any** AWS Nitro Enclave attestation document — they work independently of Epsilon:

| Package | Install | Docs |
|---------|---------|------|
| **JavaScript/Browser** | `npm install @epsilon-data/nitro-verify` | [README](https://github.com/Epsilon-Data/nitro-verify#readme) |
| **Python/CLI** | `pip install epsilon-attestation-verifier` | [README](https://github.com/Epsilon-Data/epsilon-attestation-verifier#readme) |

```bash
# Quick test — verify a real Nitro attestation in 10 seconds:
node verify-example.mjs    # JavaScript
python verify-example.py  # Python
```

Both packages provide:
- COSE_Sign1 parsing and CBOR decoding
- Certificate chain verification to AWS Nitro root CA
- ECDSA P-384 signature verification
- PCR value comparison
- Output hash verification
- Full API documentation and type definitions

### Researcher SDK (requires Epsilon platform)

```bash
pip install epsilon-sdk
```

| Command | Description |
|---------|-------------|
| `epsilon login` | Authenticate via Keycloak OAuth |
| `epsilon datasets` | List available datasets |
| `epsilon init <dataset_id>` | Generate Python classes + synthetic CSV from archetype |
| `epsilon run` | Run analysis locally against synthetic data |
| `epsilon build` | Package and submit for enclave execution |
| `epsilon change-server <url>` | Switch between production / local server |

Docs: [epsilon-sdk](https://github.com/Epsilon-Data/epsilon-sdk) | PyPI: [epsilon-sdk](https://pypi.org/project/epsilon-sdk/)

### Source-Side Encryption Proxy (requires Epsilon platform)

```bash
curl -fsSL https://raw.githubusercontent.com/Epsilon-Data/epsilon-proxy/main/scripts/install.sh | sh
epsilon-proxy register --token <TOKEN>
epsilon-proxy start
```

Data owners install epsilon-proxy next to their database. The proxy:
1. Verifies the enclave's attestation (COSE_Sign1, certificate chain, PCR0)
2. Queries the local database (credentials never leave the machine)
3. Encrypts results with the enclave's attested public key (RSA-2048-OAEP + AES-256-CBC)
4. Tunnels ciphertext to the coordinator via rathole (zero inbound ports required) — coordinator forwards to enclave via vsock

No platform component sees plaintext data.

Docs: [epsilon-proxy](https://github.com/Epsilon-Data/epsilon-proxy) | Releases: [v0.3.0](https://github.com/Epsilon-Data/epsilon-proxy/releases)

## Paper

> Nizomjon Khajiev, Aare Puussaar, Lee Shen Chu, Patrick Olivier, Lay-Ki Soon, Delvin Varghese.
> *Epsilon: A Bring-Your-Own-Data Research Platform with Trusted Verification.*
> SysTEX 2026, co-located with EuroSys 2026, Edinburgh, United Kingdom.

## License

Epsilon is provided under the [MIT License](https://github.com/Epsilon-Data/epsilon/blob/main/LICENSE)

Apache Atlas is provided under the [Apache License 2.0](https://github.com/apache/atlas/blob/master/LICENSE)

### Third-Party Software

Epsilon uses the following open-source software:

| Software | License | Usage |
|----------|---------|-------|
| [PostgreSQL](https://postgresql.org) | PostgreSQL License | Primary database |
| [Keycloak](https://keycloak.org) | Apache 2.0 | Identity & access management |
| [HashiCorp Vault](https://vaultproject.io) | BSL 1.1 | Secrets management |
| [Apache Atlas](https://atlas.apache.org) | Apache 2.0 | Metadata catalog (modified) |
| [Apache Cassandra](https://cassandra.apache.org) | Apache 2.0 | Atlas graph storage |
| [Elasticsearch](https://elastic.co) | Elastic License 2.0 / SSPL | Atlas search index |
| [Apache Kafka](https://kafka.apache.org) | Apache 2.0 | Atlas event streaming |
| [Apache ZooKeeper](https://zookeeper.apache.org) | Apache 2.0 | Kafka coordination |
| [Redis](https://redis.io) | RSALv2 / SSPLv1 | Caching |
| [NGINX](https://nginx.org) | BSD-2-Clause | Reverse proxy |
| [pgAdmin](https://pgadmin.org) | PostgreSQL License | DB admin UI (dev only) |
| [Mailpit](https://github.com/axllent/mailpit) | MIT | Email testing (dev only) |
| [keycloak-config-cli](https://github.com/adorsys/keycloak-config-cli) | Apache 2.0 | Keycloak realm provisioning |

The frontend is built using a template from [Minimal UI](https://minimals.cc/) by Minimals.
