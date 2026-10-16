# Publication status — 2026-10-17

GitHub Pages is published at https://hiroyukiyamamoto.github.io/loadings-mcp/ . The R MCP server is **not deployed**; `docs/config.json` remains null. No anonymous Cloud Run access has been granted.

The latest request supersedes the earlier plan to deploy in the shared project. **Use a dedicated project and verify cost protection first.** See [cost-control findings, estimates, pending approvals and emergency procedures](OPERATIONS.md).

## Confirmed

- GitHub main and the local checkout matched at the start of review (`e249b5a`). Existing analysis code and the loadings package are unchanged.
- The current gcloud account is authenticated. Current project `stable-century-479407-m7` contains 23 Tokyo Cloud Run services, none named loadings-mcp; no existing service was changed.
- The open billing account is JPY-denominated. IAM checks confirm permission to create budgets, configure spend caps and link projects. Budget API reads fail with 403 SERVICE_DISABLED; no API was enabled and no budget was created.
- Official Cloud Billing API documentation supports Cloud Run spend caps and nonnegative JPY amounts. Actual account acceptance/read-back and enforcement are **unverified**.
- All eight real-demo analyses succeeded in the local measurement script; observed analysis + JSON time 0.12–1.00s, sampled peak RSS up to 165.1 MiB. These are not Cloud Run measurements.

## Pending approval

Proposed dedicated project: `loadings-mcp-20261017` (availability unverified). First approve project creation, association with the existing JPY billing account, required APIs, a JPY 400 monthly Run spend cap and JPY 500 project-wide alert budget. The JPY 400 threshold reserves some headroom toward the JPY 500/month goal, but enforcement delays and non-Run charges prevent a strict total guarantee.

The deployment script now refuses a shared project and requires a read-back-verified, settled CONFIGURED Run cap <= JPY 400. Candidate private runtime: 1 CPU, 512 MiB, concurrency 1, min 0, service/revision max 1, request billing, 30s timeout. These settings remain undeployed and require Cloud Run sizing tests.

Runtime identity, registry/build permissions and private deployment follow approval. Before any anonymous publication, implement/test pre-parser body limits, a computation deadline and bounded request admission; run actual private MCP tests, then obtain separate final public-access approval. A Run timeout alone does not kill computation. Do not replace the absent cap with alerts and silently publish.

## Existing validated artifact (historical)

The unchanged metabolome/multiset implementation `e0a9279` passed [Linux R and Docker CI](https://github.com/hiroyukiyamamoto/loadings-mcp/actions/runs/38914299181). An earlier approved build in the shared project succeeded: `f877dac5-082d-47f5-95d7-9919f4d6f217`.

```text
asia-northeast1-docker.pkg.dev/stable-century-479407-m7/cloud-run-source-deploy/loadings-mcp@sha256:152a5a0b3a25a50182ed69361db9571e256b0feae97347f0849270323aa39cf9
```

This artifact is not deployed and does not include future public transport safeguards. Do not grant cross-project reader roles in the shared project without approval; build the eventual release in the dedicated project. No build was launched in this cost-control review.

## Verification status

| Item | Status |
| --- | --- |
| Official website | Public; latest reference/design publication succeeded |
| Cloud Run / endpoint | Not created; endpoint unknown |
| Spend cap / project alert | Prepared, not created; API activation and project approval required |
| Cost gate tests | Local PASS; rejects alert-only, wrong scope/currency, inactive/unsettled/excessive caps |
| R demo benchmark | All 8 methods PASS locally; sampled Windows metrics only |
| Cloud Run initialize / tools / analyses | Unverified until private deployment |
| ChatGPT / Claude manual connection | Unverified |
| Public request/body/time protection | Not implemented; blocks anonymous rollout |
| Emergency stop | Runbook prepared; not executed against a live service |

Only after public deployment approval and successful anonymous MCP tests should the actual HTTPS `/mcp` URL and free best-effort service terms be published on Pages.
