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
4. Fill in the project form:
   - **Project Name**: e.g. `University Analysis`
   - **Description**: e.g. `Sample project for artifact evaluation`
   - **Start Date**: today's date
   - **End Date**: any future date
   - **Access Type**: select **Public** (auto-approved — recommended for evaluation) or **Private** (requires manual approval for each researcher)
5. When asked **"How should the platform access your data?"**, choose one:

   - **Cloud Connect** — provide database credentials directly. The platform connects to your database. Simpler setup, suitable for cloud-hosted databases.
   - **Epsilon Proxy** — install a lightweight agent next to your database. Data is encrypted locally before leaving your network. More secure for sensitive data.

   > **For evaluation:** Cloud Connect is easier if you have a cloud-hosted PostgreSQL (e.g. Neon, Supabase, RDS). Use Proxy if you want to test the full source-side encryption flow.

6. Click **Create** — your project appears in the Data Hub dashboard

![Step 1: Create Project](static/Step1.gif)
> 📹 [Watch video walkthrough (Step 1)](https://epsilon-new.s3.ap-southeast-2.amazonaws.com/Step1.mp4)

### Step 2a: Connect via Cloud Connect

If you chose **Cloud Connect**, enter your database credentials:

| Field | Example |
|-------|---------|
| Hostname | `your-db-host.neon.tech` |
| Port | `5432` |
| Username | `your_user` |
| Password | `your_password` |
| Database | `your_database` |
| SSL | On (for cloud databases) |

The platform will crawl your database schema automatically (~10 seconds). Skip to **Step 3**.

### Step 2b: Connect via Epsilon Proxy

If you chose **Epsilon Proxy**, the data stays on your machine — epsilon-proxy encrypts it locally and sends only ciphertext to the platform.

**Prerequisites:** You need a local PostgreSQL database with some data. We provide a seed script that creates a sample university database (5 universities, 50 students, 23 subjects, 64 enrollments):

```bash
# 1. Create and seed the sample database (requires local PostgreSQL)
createdb epsilon_sample
psql -d epsilon_sample < scripts/seed-sample-db.sql

# 2. Verify
psql -d epsilon_sample -c "\
  SELECT 'university' AS table, count(*) FROM university UNION ALL \
  SELECT 'student', count(*) FROM student UNION ALL \
  SELECT 'subject', count(*) FROM subject UNION ALL \
  SELECT 'student_subject', count(*) FROM student_subject;"
```

Expected output:

```
      table      | count
-----------------+-------
 university      |     5
 student         |    50
 subject         |    23
 student_subject |    64
```

> **Don't have PostgreSQL?** Install via `brew install postgresql@16` (macOS), `apt install postgresql` (Ubuntu), or [Docker](https://hub.docker.com/_/postgres).

You can also use any existing PostgreSQL database with data instead.

**Install and connect epsilon-proxy:**

```bash
# 1. Install epsilon-proxy (downloads Go binary + rathole + tbls)
curl -fsSL https://raw.githubusercontent.com/Epsilon-Data/epsilon-proxy/main/scripts/install.sh | sh

# 2. Get your project token from the Data Hub UI (Project Settings → Proxy → Generate Token)
#    Then register:
epsilon-proxy register --token <YOUR_PROJECT_TOKEN>
```

During registration, you'll be prompted for database credentials. Choose option `[1] Full URL` and enter:

```
postgres://your_user:your_password@localhost:5432/epsilon_sample
```

Credentials are stored locally at `~/.epsilon-proxy/config.yaml` and **never sent to the platform**.

```bash
# 3. Start the proxy — it connects to the platform and crawls your schema
epsilon-proxy start
```

The proxy will:
- Register with the platform and appear in your Data Hub project
- Crawl your database schema automatically (~10 seconds)
- Stay running and listen for execution requests

When a researcher submits a job, you'll see logs like:

```
[ATTESTATION] Verified: PCR0=a5373aaa... module=i-076... public_key_match=true
[QUERY] request_id=coord-JOB-XXX rows=230 cols=5 query_ms=5 encrypt_ms=0 size=16896
```

- `[ATTESTATION]` — the proxy verified the enclave's identity (COSE_Sign1 signature, AWS cert chain, PCR0) and confirmed the public key is bound to the attestation. Data is only released after this check passes.
- `[QUERY]` — the proxy queried your local database, encrypted the results with the enclave's public key, and sent ciphertext through the tunnel. The platform never sees plaintext.

> **Note:** Database credentials are stored locally only in `~/.epsilon-proxy/config.yaml` — they are never sent to the platform.

![Step 2: Install Proxy](static/Step2.gif)
> 📹 [Watch video walkthrough (Step 2)](https://epsilon-new.s3.ap-southeast-2.amazonaws.com/Step2.mp4)

### Step 3: Map Archetype and Publish

An **Archetype** is a tree-structured schema that defines which columns researchers can access. It acts as a consent boundary — researchers only see data through the archetype, never the raw database.

Example archetype for the sample university database:

```
              ┌──────────────────┐
              │ University Study │  ← Root (archetype)
              └────────┬─────────┘
              ┌────────┼────────┐
              ▼        ▼        ▼
         university  student  subject        ← Nodes (tables)
          │  │  │      │      │ │ │
          ▼  ▼  ▼      ▼      ▼ ▼ ▼
        name  country year  name code credits ← Leaves (columns)
              year          department
```

To create an archetype:

1. After the schema crawl completes, click **Create Archetype** in your project
2. Select which tables and columns to expose in the tree view
3. Optionally set column-level controls (visible, anonymized, aggregated)
4. Click **Publish** — the dataset is now visible to researchers in Browse Hub

![Step 3: Map Archetype and Publish](static/Step3.gif)
> 📹 [Watch video walkthrough (Step 3)](https://epsilon-new.s3.ap-southeast-2.amazonaws.com/Step3.mp4)

---

## Flow B: Researcher — Request Access and Submit a Job

### Step 1: Browse and join a dataset

1. Open https://app.epsilon-data.org
2. Log in with your reviewer account (e.g. `reviewer1@epsilon-data.org` / `secret12345`)
3. Go to **Browser Hub → Browse Projects** to see published datasets
4. Click on a dataset and send a **Connection Request**
   - **Public datasets** are auto-approved instantly
   - **Private datasets** require the Data Owner to approve
5. Check your request status at **Browse Hub → Track Requests**
6. Once approved, note the **Dataset ID** — you can find it using:
   ```bash
   pip install epsilon-sdk
   epsilon login
   epsilon datasets    # Lists all datasets you have access to, with IDs
   ```

![Step 1: Browse and Join Dataset](static/Step4.gif)
> 📹 [Watch video walkthrough (Step 4)](https://epsilon-new.s3.ap-southeast-2.amazonaws.com/Step4.mp4)

### Step 2: Prepare your research repository

1. Fork or use the [epsilon-research-template](https://github.com/Epsilon-Data/epsilon-research-template) as a GitHub template
2. Install the Epsilon SDK and initialize your project:
   ```bash
   pip install epsilon-sdk
   epsilon login                          # Authenticate with Epsilon
   epsilon init <dataset_id>              # Generates project.yml, main.py, and generated/ directory
   ```
3. Edit `main.py` with your analysis code (uses generated Python classes from the archetype)
4. Test locally: `epsilon run` (runs against synthetic data)
5. Build for deployment: `epsilon build` (creates `build/` directory with `build.yml` and packaged code)
6. Push to GitHub

![Step 2: Research Template and SDK](static/Step5.gif)
> 📹 [Watch video walkthrough (Step 5)](https://epsilon-new.s3.ap-southeast-2.amazonaws.com/Step5.mp4)

### Step 3: Submit a research job

1. Open https://analysis.epsilon-data.org
2. Log in with your reviewer account (e.g. `reviewer1@epsilon-data.org` / `secret12345`)
3. Connect your GitHub account — you'll be asked to authorize the Epsilon GitHub App
   > **Note for reviewers:** The GitHub OAuth requests access to public and private repositories. If you prefer not to grant access to your main account, you can create a temporary GitHub account for evaluation purposes. We only read the repository you point to — no writes are performed.
4. Create a **Workspace** pointing to your research repository
5. Click **Submit Job**

### Step 4: View job details and verify on Trust Hub

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

Click **Verify on Trust Hub** to independently verify the attestation:
- **TEE Hardware** — COSE_Sign1 signature verified against AWS Nitro root
- **Enclave Image** — PCR0/1/2 compared against [published values](https://github.com/Epsilon-Data/epsilon-enclave/blob/main/published/pcr-registry.json)
- **Certificate Chain** — AWS root → intermediate → enclave certificate
- **Data Transport** — E2E encryption architecture ([epsilon-proxy](https://github.com/Epsilon-Data/epsilon-proxy))
- **Execution Proof** — job ID, script hash, dataset hash, output hash bound in attestation
- **Output Integrity** — SHA-256 hash match

![Step 4: Job Detail and Trust Hub Verification](static/Step6.gif)
> 📹 [Watch video walkthrough (Step 6)](https://epsilon-new.s3.ap-southeast-2.amazonaws.com/Step6.mp4)

### Step 5: Manual attestation verification

You can independently verify any attestation document:

1. From the job detail page, copy the **Raw Attestation Document (Base64)**
2. Go to https://trust.epsilon-data.org/verify
3. Paste the base64 document and click **Verify**
4. The Trust Hub performs full client-side cryptographic verification in your browser — no server trust required

![Step 5: Manual Attestation Verification](static/Step7.gif)
> 📹 [Watch video walkthrough (Step 7)](https://epsilon-new.s3.ap-southeast-2.amazonaws.com/Step7.mp4)

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

---

## Standalone Verification (no platform required)

Verify any Nitro attestation document independently — no Epsilon account, no platform access needed:

**JavaScript/Browser:**
```bash
npm install @epsilon-data/nitro-verify
```
```javascript
import { verifyAttestation } from "@epsilon-data/nitro-verify";
const result = await verifyAttestation(base64Doc, {
    expectedPcrs: { pcr0: "a537..." },
    allowExpired: true  // historical attestations have ~3hr cert lifetime
});
console.log(result.valid, result.steps);
```

**Python/CLI:**
```bash
pip install epsilon-attestation-verifier
```
```python
from epsilon_verifier import verify_attestation
result = verify_attestation(
    attestation_doc="<base64>",
    expected_pcr0="a537...",
    allow_expired=True
)
print(result.valid, result.pcr0)
```

These packages work with **any** AWS Nitro Enclave attestation — not just Epsilon.

---

## Notes

- Production uses **real AWS Nitro Enclaves** — attestation documents are hardware-signed and cryptographically verifiable
- The Trust Hub performs verification using [@epsilon-data/nitro-verify](https://github.com/Epsilon-Data/nitro-verify) — no server trust required
- Test accounts are pre-seeded and may be reset periodically
- The enclave source code is open: [epsilon-enclave](https://github.com/Epsilon-Data/epsilon-enclave)
