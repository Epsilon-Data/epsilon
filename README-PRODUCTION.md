# Option A: Try on Production (Recommended for Evaluation)

No setup required — use the live instance with pre-configured test accounts.

## Access

- **URL**: <PRODUCTION_URL>

### Test Accounts

| Role | Email | Password |
|------|-------|----------|
| Data Owner | owner@epsilon-data.org | secret |
| Data Admin | dbadmin@epsilon-data.org | secret |
| Researcher | researcher@epsilon-data.org | secret |

## Full Pipeline Walkthrough

### Step 1: Log in as Data Owner → Register a Dataset

Sign in with the **Data Owner** account and register a dataset through the Data Hub.

<!-- GIF_PLACEHOLDER: gifs/option-a-step1-register-dataset.gif -->

### Step 2: Log in as Researcher → Submit a Research Job

Switch to the **Researcher** account. Create a new workspace, select the registered dataset, and submit a research job.

<!-- GIF_PLACEHOLDER: gifs/option-a-step2-submit-job.gif -->

### Step 3: View Job Execution Results

Once the job completes, view the execution results in the workspace.

<!-- GIF_PLACEHOLDER: gifs/option-a-step3-view-results.gif -->

### Step 4: Verify Attestation Receipt in Trust Center

Open the Trust Center to inspect the attestation document. Verify the cryptographic signature binding the code, data, and execution environment.

<!-- GIF_PLACEHOLDER: gifs/option-a-step4-verify-attestation.gif -->

## Notes

- Production uses **real AWS Nitro Enclaves** with hardware-signed attestation
- Attestation documents are cryptographically verifiable — the Trust Center performs client-side verification using [nitro-verify](https://github.com/Epsilon-Data/nitro-verify)
- Test accounts are pre-seeded and may be reset periodically
