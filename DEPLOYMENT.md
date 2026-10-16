# Publication status — 2026-10-17

GitHub Pages is published at https://hiroyukiyamamoto.github.io/loadings-mcp/ . The R MCP server is **not deployed**; `docs/config.json` remains null. No anonymous Cloud Run access has been granted.

The user chose the existing project and explicitly approved that the JPY 400 Run cap can also pause all 23 existing services. **Budgets are now configured; private deployment and public access remain unexecuted.** See [cost-control findings, estimates, pending approvals and emergency procedures](OPERATIONS.md).

## Confirmed

- GitHub main and the local checkout matched at the start of review (`e249b5a`). Existing analysis code and the loadings package are unchanged.
- The current gcloud account is authenticated. Current project `stable-century-479407-m7` contains 23 Tokyo Cloud Run services, none named loadings-mcp; no existing service was changed.
- The open billing account is JPY-denominated. Budget API was enabled after approval. A JPY 400 monthly Cloud Run spend cap and a separate JPY 500 monthly project-wide notification budget were created and read back. Existing JPY 10,000 account budget is unchanged.
- Official Cloud Billing API documentation supports Cloud Run spend caps and nonnegative JPY amounts. Account acceptance/read-back succeeded with state CONFIGURED. Actual enforcement and invoice totals remain **unverified**.
- All eight real-demo analyses succeeded in the local measurement script; observed analysis + JSON time 0.12–1.00s, sampled peak RSS up to 165.1 MiB. These are not Cloud Run measurements.

## Pending approval

Selected project: `stable-century-479407-m7`; no new project or billing association was created. The cap covers ALL Cloud Run services there and includes existing usage. Budget IDs and exact next-stage commands are in [OPERATIONS.md](OPERATIONS.md).

The deployment script requires a verified, settled CONFIGURED Run cap <= JPY 400 and an explicit shared-project acknowledgment. Initial private runtime: 1 CPU, 512 MiB, concurrency 1, min 0, service/revision max 1, request billing, 30s timeout. Actual Cloud Run sizing remains unverified.

Next approval: create the dedicated role-free runtime identity and deploy only the new private service using the already validated image (no new build). No role-free identity or service of this name existed at preflight. Public request safeguards, private MCP tests and separate final anonymous-access approval still remain.

## Existing validated artifact (historical)

The unchanged metabolome/multiset implementation `e0a9279` passed [Linux R and Docker CI](https://github.com/hiroyukiyamamoto/loadings-mcp/actions/runs/38914299181). An earlier approved build in the shared project succeeded: `f877dac5-082d-47f5-95d7-9919f4d6f217`.

```text
asia-northeast1-docker.pkg.dev/stable-century-479407-m7/cloud-run-source-deploy/loadings-mcp@sha256:152a5a0b3a25a50182ed69361db9571e256b0feae97347f0849270323aa39cf9
```

This artifact is not deployed and does not include future public transport safeguards. It can be used for the approved-project private trial; a new image will be needed once public transport safeguards are added. No build was launched in this cost-control review.

## Verification status

| Item | Status |
| --- | --- |
| Official website | Public; latest reference/design publication succeeded |
| Cloud Run / endpoint | Not created; endpoint unknown |
| Spend cap / project alert | CREATED and read back: JPY 400 Run cap CONFIGURED; JPY 500 alerts-only; all existing Run services are in scope |
| Cost gate tests | Local PASS; rejects alert-only, wrong scope/currency, inactive/unsettled/excessive caps |
| R demo benchmark | All 8 methods PASS locally; sampled Windows metrics only |
| Cloud Run initialize / tools / analyses | Unverified until private deployment |
| ChatGPT / Claude manual connection | Unverified |
| Public request/body/time protection | Not implemented; blocks anonymous rollout |
| Emergency stop | Runbook prepared; not executed against a live service |

Only after public deployment approval and successful anonymous MCP tests should the actual HTTPS `/mcp` URL and free best-effort service terms be published on Pages.
