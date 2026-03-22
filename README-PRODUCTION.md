# Option A: Try on Production (Recommended for Evaluation)

No setup required — use the live instance with pre-configured test accounts and real AWS Nitro Enclaves.

## Access

| Service | URL |
|---------|-----|
| Data Hub | https://app.epsilon-data.org |
| Job Scheduler | https://analysis.epsilon-data.org |
| Trust Hub | https://trust.epsilon-data.org |

### Test Accounts

| Role | Email | Password |
|------|-------|----------|
| Reviewer 1 | `reviewer1@epsilon-data.org` | `secret12345` |
| Reviewer 2 | `reviewer2@epsilon-data.org` | `secret12345` |
| Reviewer 3 | `reviewer3@epsilon-data.org` | `secret12345` |
| Reviewer 4 | `reviewer4@epsilon-data.org` | `secret12345` |
| Reviewer 5 | `reviewer5@epsilon-data.org` | `secret12345` |

## Pre-seeded Data

The production instance already has published datasets you can use immediately as a Researcher — skip to **Flow B, Step 1** if you just want to submit a job.

---

## Flow A: Data Owner — Register a Dataset

### Step 1: Create a new project

1. Open https://app.epsilon-data.org
2. Log in with your reviewer account (e.g. `reviewer1@epsilon-data.org` / `secret12345`)
3. Click **New Project** in the Data Hub
4. Fill in project name, description, and dates
5. Choose **Public** (auto-approved access) or **Private** (requires manual approval)

![Step 1: Create Project](static/Step1.gif)

### Step 2: Install epsilon-proxy and connect your database

The data stays on your machine — epsilon-proxy encrypts it locally and sends only ciphertext to the platform.

1. Follow the setup guide: [epsilon-proxy](https://github.com/Epsilon-Data/epsilon-proxy)
2. Point it to your local PostgreSQL database
3. The proxy will register itself with the platform and appear in the Data Hub
4. Wait for the data broker to crawl the schema (~10s)

![Step 2: Install Proxy](static/Step2.gif)

### Step 3: Map Archetype and Publish

1. Select which tables and columns to expose
2. Map them to an **Archetype** — a semantic data structure that defines what researchers can access
3. Choose column-level access controls (which columns are visible, which are anonymized)
4. Click **Publish** — the dataset is now visible to researchers in the Shared tab

![Step 3: Map Archetype and Publish](static/Step3.gif)

---

## Flow B: Researcher — Request Access and Submit a Job

### Step 1: Request access to a dataset

1. Open https://app.epsilon-data.org
2. Log in with your reviewer account (e.g. `reviewer1@epsilon-data.org` / `secret12345`)
3. Go to the **Shared** tab — browse published datasets
4. Click on a dataset and send a **Connection Request**
   - **Public datasets** are auto-approved instantly
   - **Private datasets** require the Data Owner to approve
5. Once approved, note the **Dataset ID** and **Archetype ID** — you'll need them for your analysis script

### Step 2: Prepare your research repository

1. Fork or use the [epsilon-research-template](https://github.com/Epsilon-Data/epsilon-research-template) as a GitHub template
2. Configure `build/build.yml` with your Dataset ID and Archetype ID:
   ```yaml
   datasets:
     - dataset_id: "your-dataset-id"
       archetype_id: "your-archetype-id"
   ```
3. Write your analysis in `build/main.py` using the Epsilon SDK
4. Push to GitHub

### Step 3: Submit a research job

1. Open https://analysis.epsilon-data.org
2. Log in with your reviewer account (e.g. `reviewer1@epsilon-data.org` / `secret12345`)
3. Connect your GitHub account (already configured on production)
4. Create a **Workspace** pointing to your research repository
5. Click **Submit Job**

### Step 4: Monitor execution

The job progresses through the coordinator pipeline:

```
Queued → Cloned → AI Agent (code review) → Data Fetched → Encrypted → Executed in TEE → Attestation → Completed
```

The job detail page shows:
- **Execution Output** — the result of your analysis with a **Verify SHA-256** button
- **Execution Proof** — repo, commit, script hash, dataset hash, output hash (all hardware-signed)
- **Server Verification** — certificate chain, signature, PCR match status
- **Execution Metrics** — data fetch time, encryption time, enclave execution time
- **AI Policy Analysis** — CrewAI agent review (informational, does not block execution)

### Step 5: Verify attestation on the Trust Hub

1. Click **Verify on Trust Hub** from the job detail page (or open https://trust.epsilon-data.org)
2. The Trust Hub performs **client-side verification** entirely in your browser:
   - **TEE Hardware** — COSE_Sign1 signature verified against AWS Nitro root
   - **Enclave Image** — PCR0/1/2 compared against [published values](https://github.com/Epsilon-Data/epsilon-enclave/blob/main/published/pcr-registry.json)
   - **Certificate Chain** — AWS root → intermediate → enclave certificate
   - **Data Transport** — E2E encryption architecture ([epsilon-proxy](https://github.com/Epsilon-Data/epsilon-proxy))
   - **Execution Proof** — job ID, script hash, dataset hash, output hash bound in attestation
   - **Output Integrity** — SHA-256 hash match

---

## What Makes This Different from Local Mode

| | Production | Local |
|---|---|---|
| Hardware | AWS Nitro Enclaves (real TEE) | Simulated Python process |
| Attestation | Signed by AWS Nitro hardware | Signed by local ECDSA CA |
| PCR Values | Real enclave measurements | Placeholder values |
| Certificate Chain | AWS root of trust | Epsilon Local Root CA |
| Trust Hub verification | All checks pass | Certificate chain fails (expected) |
| Data transport | epsilon-proxy (source-side encryption) or Lambda middleware | Local HTTP middleware |

## Notes

- Production uses **real AWS Nitro Enclaves** — attestation documents are hardware-signed and cryptographically verifiable
- The Trust Hub performs verification using [@epsilon-data/nitro-verify](https://github.com/Epsilon-Data/nitro-verify) — no server trust required
- Test accounts are pre-seeded and may be reset periodically
- The enclave source code is open: [epsilon-enclave](https://github.com/Epsilon-Data/epsilon-enclave)
