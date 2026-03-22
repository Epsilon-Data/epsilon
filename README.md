# Epsilon

**A Bring-Your-Own-Data Research Platform with Trusted Verification**

Epsilon is an open-source platform for analyzing sensitive research data with per-execution verification using AWS Nitro Enclaves. Researchers link their own datasets without uploading data to platform infrastructure, and receive TEE-signed verification receipts binding specific code to specific data.

> SysTEX 2026 — 9th Workshop on System Software for Trusted Execution

## Getting Started

Choose one of two evaluation paths:

| | Option | Best For | Time |
|---|--------|----------|------|
| A | [Try on Production](README-PRODUCTION.md) | Quick evaluation, no setup | ~10 min |
| B | [Run Locally](README-LOCAL.md) | Full source inspection, offline | ~30 min |

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Frontend (:3000)                      │
│                     React + TypeScript                       │
└──────────────────────────┬──────────────────────────────────┘
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
     ┌──────────────┐ ┌────────┐ ┌──────────────┐
     │ API (:3334)  │ │Keycloak│ │Job Scheduler │
     │ NestJS       │ │(:8080) │ │(:3005)       │
     └──────┬───────┘ └────────┘ └──────────────┘
            │
     ┌──────┴───────┐
     │  PostgreSQL   │ ◄── Coordinator Workers
     │  (:5432)      │     (fetcher → clone → executor)
     └──────┬───────┘
            │                        ┌──────────────────┐
            │                        │ Enclave (:5005)  │
            │                        │ AWS Nitro / Local│
            └───────────────────────►│ Simulation       │
                                     └────────┬─────────┘
                                              │
                                     ┌────────▼─────────┐
                                     │ Trust Center     │
                                     │ (:3001)          │
                                     │ Verification UI  │
                                     └──────────────────┘
```

## Repository Structure

This is the main orchestration repo. Component source code lives in sibling directories:

| Component | Repo | Description |
|-----------|------|-------------|
| API | [api](https://github.com/Epsilon-Data/api) | NestJS backend — datasets, archetypes, jobs |
| Frontend | [frontend](https://github.com/Epsilon-Data/frontend) | React UI — Data Hub, archetype builder |
| Coordinator | [coordinator](https://github.com/Epsilon-Data/coordinator) | Python workers — job fetcher, clone, executor |
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

## Paper

> Nizomjon Khajiev, Aare Puussaar, Chu Lee Shen, Patrick Olivier, Lay-Ki Soon, Delvin Varghese.
> *Epsilon: A Bring-Your-Own-Data Research Platform with Trusted Verification.*
> SysTEX 2026, co-located with EuroSys 2026, Edinburgh, United Kingdom.

## License

Apache 2.0
