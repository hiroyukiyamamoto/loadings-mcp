# Cost control and operations

Reviewed 2026-10-17 (Asia/Tokyo). **No hosted MCP endpoint exists yet. No project, billing link, budget, API activation or IAM change was made during this review.** GitHub Pages remains public. The following is a staged proposal requiring approval.

## Observed environment

- GitHub main matches the local implementation. Existing Linux R/Docker validation remains applicable to the analysis code.
- Active gcloud project: `stable-century-479407-m7`. There are 23 existing Cloud Run services in Tokyo, none named loadings-mcp. Do not put this service's spend cap on that shared project.
- Five projects are visible; none is a dedicated loadings-mcp project. Proposed new ID: `loadings-mcp-20261017` (global availability unverified; stop if unavailable).
- The open billing account uses **JPY**. Billing IAM permission checks returned budget creation, spend-cap configuration and project billing-association permissions. This is not proof of successful cap creation or enforcement.
- Budget API reads fail with **403 SERVICE_DISABLED** for the current quota project. Nothing was enabled. Existing budgets and actual billed costs could not be inspected through this API. No claim of zero existing spend is made.

## Spend cap findings

Cloud Run is eligible, service ID `152E-C115-5142`. A cap covers one project and one service, so it would also pause any other Cloud Run workloads in that project. Reseller accounts are excluded; this account has no master billing account, but final acceptance still requires a successful create/read-back. Monthly caps notify owners/admins at 50/80/100%, block new usage when enforced, and reset next month. Enforcement is delayed and overages remain billable. [Google spend-cap guide](https://docs.cloud.google.com/billing/docs/how-to/budgets-spend-caps)

The API allows a nonnegative specified amount (documented minimum **0**); use a positive operational threshold. Currency must match the account. **JPY 500 can be requested directly**; acceptance is unverified until creation. We propose **JPY 400** for Cloud Run to leave some room below the JPY 500 total target. [API amount specification](https://docs.cloud.google.com/billing/docs/reference/budget/rest/v1/billingAccounts.budgets#BudgetAmount)

The proposed request uses gross costs excluding credits, monthly scope, the three required thresholds, project recipients and `spendCap.inputState=CONFIGURED`. `scripts/spend-cap.R` creates only with an explicit approval environment flag; `verify` rejects alerts-only budgets, wrong scope/currency, lifted/enforced/reconciling caps and caps above JPY 400. Verification reads back configuration; it does **not** prove that enforcement has happened. [Official API guide](https://docs.cloud.google.com/billing/docs/how-to/budget-api-spend-cap)

No USD conversion is needed for this JPY account. For USD cost illustrations, Google sets local conversion rates monthly; use the actual billing conversion rate, not a market quote. In an existing billing export, JPY cost / `currency_conversion_rate` gives USD. No BigQuery export is enabled by this project. [Currency rules](https://docs.cloud.google.com/billing/docs/resources/currency)

## Estimate and uncovered charges

Planning assumptions: 1 vCPU, 512 MiB, request billing, no minimum instances, Tokyo Tier 1. List price is USD 0.000024/vCPU-second + USD 0.0000025/GiB-second and USD 0.40/million requests. This totals USD 0.00002525 per active second before request charges. Free allocations are shared across the billing account; do not assume they remain available. [Cloud Run pricing](https://cloud.google.com/run/pricing)

Illustrative exchange rate **JPY 150/USD is an assumption, not the verified billing rate**:

| Scenario | Illustrative cost before free credits, networking, storage, tax |
| --- | --- |
| 1,000 requests averaging 5 billed seconds | ~JPY 19 |
| 10,000 requests averaging 5 billed seconds | ~JPY 190 |
| One instance continuously active for 30 days | ~JPY 9,817 + request charges |

The last scenario demonstrates why max-instances=1 is insufficient. JPY 400 gross could be reached after approximately 29 active hours at the assumed rate. Cold starts, serialization and actual traffic change this estimate. Since caps exclude credits, they can pause usage even when the eventual net invoice is low.

Other charges are outside a Cloud Run-only cap:

- Artifact Registry: about USD 0.10/GiB-month beyond the account's shared 0.5 GiB free allocation, plus applicable transfer. Keep one release initially; inspect compressed artifact storage before deciding cleanup. No automated deletion of active images. [Registry pricing](https://cloud.google.com/artifact-registry/pricing)
- Cloud Build: e2-standard-2 costs USD 0.006/minute beyond available promotional free minutes. The previous build took about 9m36s. One proposed build with a 900-second timeout is about USD 0.09 build compute at most at that rate, excluding other charges. No automatic rebuild trigger. Build source buckets also retain storage unless cleaned. [Build pricing](https://cloud.google.com/build/pricing)
- Cloud Logging: first 50 GiB/project/month is free; additional ordinary storage ingestion USD 0.50/GiB. High traffic can generate costs even for rejected requests. Use default retention, no payload logging or external exports. [Observability pricing](https://cloud.google.com/products/observability/pricing)
- Network transfer, taxes and any unrelated resources are not guaranteed covered. No load balancer, Cloud Armor, VPC connector, NAT, database, Scheduler or paid external monitoring is proposed.

**JPY 500/month is a target, not a guaranteed invoice ceiling.** A normal all-service JPY 500 budget is an additional notification only, not a substitute for the cap. Inspect billing Reports by dedicated project for actual costs, including storage/build/network/taxes. The Run cap does not cover the rest of the billing account.

## Proposed staged rollout (not executed)

1. Approve creation of `loadings-mcp-20261017`, link the existing JPY billing account, and enable only required APIs there (Budget, Billing, Run, Artifact Registry, IAM, Cloud Build). Leave gcloud's current project unchanged; every command supplies `--project`.
2. Create the JPY 400 monthly Run spend cap and a separate JPY 500 project-wide alerts-only budget. Read back exact project/service/currency/amount/state. If creation/verification fails, do not deploy or publish; report the reason and request approval for any alternative.
3. Approve a dedicated role-free runtime service account, one Docker registry, one bounded build, and the private service. New project's service agents/build identity may require project-local build/storage/artifact permissions: enumerate these before granting; no roles in existing projects. Build image in the dedicated project rather than granting cross-project access to the old registry.
4. Deploy privately using `scripts/deploy.sh`. Initial candidate: min=0/max=1 at service and revision, concurrency=1, 1 CPU, 512 MiB, request billing, timeout=30s. Benchmark memory/latency in Cloud Run, including cold starts and maximum accepted data. Stop/revise if 512 MiB is insufficient. No public IAM yet.
5. Before public approval, add/test pre-parser request-size limits, an actual computation deadline (killable worker), and bounded global request admission. The current server has dimension validation but **does not yet have these transport protections**. A Cloud Run timeout returns 504 and does not itself terminate computation. In-process throttling resets when an instance restarts and is not a durable monthly limit. Do not call this DoS protection or a bill ceiling. [Timeout behavior](https://docs.cloud.google.com/run/docs/configuring/request-timeout)
6. Test private endpoint with `scripts/smoke-remote.R`: initialize, all four tools/eight methods, invalid input and JSON. Also test oversized bodies, rate rejection, hard deadline, connection failures and recovery. HTTP/R-client success is separate from manual ChatGPT/Claude success.
7. Present measured results, cap configuration and remaining risks, then obtain **separate final approval for anonymous access** (`allUsers` Run invoker only on this service). Repeat tests anonymously before publishing the actual endpoint in `docs/config.json` and documenting free best-effort access, limits and possible suspension.

Example budget commands **after infrastructure approval and creation**, from repository root:

```sh
export GOOGLE_CLOUD_PROJECT=loadings-mcp-20261017
export BILLING_ACCOUNT_ID=YOUR_APPROVED_JPY_BILLING_ACCOUNT
Rscript --vanilla scripts/spend-cap.R plan
# Only after explicit budget creation approval:
APPROVE_BUDGET_CREATE=yes Rscript --vanilla scripts/spend-cap.R create
Rscript --vanilla scripts/spend-cap.R verify
```

First-stage infrastructure commands awaiting approval (not executed):

```sh
gcloud projects create loadings-mcp-20261017 --name='loadings MCP'
gcloud billing projects link loadings-mcp-20261017 --billing-account="$BILLING_ACCOUNT_ID"
gcloud services enable billingbudgets.googleapis.com cloudbilling.googleapis.com run.googleapis.com artifactregistry.googleapis.com iam.googleapis.com cloudbuild.googleapis.com --project=loadings-mcp-20261017
```

Then use the budget commands above. Prepare the separate **alerts-only** budget with the same single project filter, monthly period, JPY 500 specified amount, default billing recipients and project recipients, and 50/80/100% current-spend thresholds; omit `services` (all services), exclude no service costs, and **omit `spendCap`**. Read it back as a notification budget; never accept it as the deployment gate. Stop on any project-name conflict, denied permission, unsupported amount or unavailable spend-cap feature. No fallback IAM grant, billing-account replacement or alternative fee control is automatically authorized.

The create operation does not lift or overwrite existing caps. If the API reports a duplicate scope, inspect it; do not delete a budget automatically. The account ID/token is not written to the repository.

## Measurements and verification

`Rscript --vanilla scripts/benchmark.R` runs each real packaged demo in a separate R process and samples total process RSS every 20ms. Windows R 4.4.0 results on 2026-10-17:

| Method | Analysis + JSON seconds | Sampled peak RSS MiB |
| --- | ---: | ---: |
| PCA | 0.12 | 83.2 |
| OS-PCA | 0.33 | 165.1 |
| PLS-ROG | 0.12 | 83.7 |
| PLS-DA | 0.12 | 83.5 |
| RCCA-DA | 0.18 | 92.2 |
| Multiset PLS | 0.71 | 136.0 |
| Multiset PLS-ROG | 0.75 | 135.8 |
| Unsupervised multiset PLS | 1.00 | 164.0 |

These exclude HTTP and Cloud Run cold starts; sampling can miss peaks. They support an initial 512 MiB/30s trial, **not** a verified production sizing or maximum-input guarantee. Results are saved under ignored `test-results/benchmark.json`.

## Monitoring and emergency procedure

Use built-in Cloud Run Metrics (request count, 4xx/5xx, latency, CPU, memory) and Cloud Billing Reports filtered to the dedicated project. For monthly request totals, choose metric `run.googleapis.com/request_count`, service `loadings-mcp`, month interval and sum; group by `response_code_class` for errors. Inspect memory after each method/cold start. No uptime polling, custom metrics or paid alert policies are configured yet. Spend-cap emails go to billing admins/project owners automatically. [Run monitoring](https://docs.cloud.google.com/run/docs/monitoring)

Read-only checks after deployment:

```sh
gcloud run services describe loadings-mcp --project loadings-mcp-20261017 --region asia-northeast1
gcloud logging read 'resource.type="cloud_run_revision" AND resource.labels.service_name="loadings-mcp" AND severity>=ERROR' --project loadings-mcp-20261017 --freshness=24h --limit=100
Rscript --vanilla scripts/spend-cap.R verify
```

Emergency: revoke public reachability by changing **only this service** to internal ingress:

```sh
gcloud run services update loadings-mcp --project loadings-mcp-20261017 --region asia-northeast1 --ingress internal
```

Then verify external MCP requests fail. In-flight work may continue; if necessary delete **only this dedicated service** to stop its runtime:

```sh
gcloud run services delete loadings-mcp --project loadings-mcp-20261017 --region asia-northeast1
```

Do not disable billing on the shared project or lift a cap automatically. Deleting the service does not remove image/log/build-source storage charges. Restoration needs an approved redeploy or ingress change, valid cost protection and fresh connectivity tests. Spend caps reset monthly and can resume service automatically; emergency internal ingress persists until explicitly changed. Update the site's service status if suspended.
