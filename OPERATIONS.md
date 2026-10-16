# Cost control and operations

Updated 2026-10-17 (Asia/Tokyo). **The MCP endpoint is deployed privately and authenticated tests pass; anonymous access is disabled.** Following explicit approval to include all existing Cloud Run services, the existing project is retained, Budget API was enabled, and the two budgets below were created and read back. No new project or billing link was created. The role-free runtime identity and private service were subsequently created under explicit approval; no public IAM change was made. GitHub Pages remains public.

## Observed environment

- GitHub main matches the local implementation. Existing Linux R/Docker validation remains applicable to the analysis code.
- Active gcloud project: `stable-century-479407-m7`. There are 23 existing Cloud Run services in Tokyo, and the new loadings-mcp service is now the 24th. The user explicitly approved applying the cap to this shared project, including all 23 existing services.
- No dedicated project will be created: the user chose `stable-century-479407-m7`. Project number: `121643671058`.
- The open billing account uses **JPY**. Billing IAM permission checks returned budget creation, spend-cap configuration and project billing-association permissions. Cap creation and CONFIGURED-state read-back subsequently succeeded. An actual enforcement event has not been tested.
- Budget API initially returned 403 SERVICE_DISABLED; it was enabled after approval. Existing account-wide JPY 10,000 alerts-only budget was inspected and left unchanged. Actual billed costs are not returned by this budget configuration API; no zero-cost claim is made.

## Spend cap findings

Cloud Run is eligible, service ID `152E-C115-5142`. A cap covers one project and one service, so it would also pause any other Cloud Run workloads in that project. Reseller accounts are excluded; this account has no master billing account, and a JPY 400 cap was successfully created/read back. Monthly caps notify owners/admins at 50/80/100%, block new usage when enforced, and reset next month. Enforcement is delayed and overages remain billable. [Google spend-cap guide](https://docs.cloud.google.com/billing/docs/how-to/budgets-spend-caps)

The API allows a nonnegative specified amount (documented minimum **0**); use a positive operational threshold. Currency must match the account. **JPY 400 was accepted and configured** for Cloud Run; a JPY 500 all-service notification budget was also created. The Run cap includes existing services, not only loadings-mcp. [API amount specification](https://docs.cloud.google.com/billing/docs/reference/budget/rest/v1/billingAccounts.budgets#BudgetAmount)

The configured cap uses gross costs excluding credits, monthly scope, the three required thresholds, project recipients and `spendCap.inputState=CONFIGURED`. `scripts/spend-cap.R` creates only with an explicit approval environment flag; `verify` rejects alerts-only budgets, wrong scope/currency, lifted/enforced/reconciling caps and caps above JPY 400. Verification reads back configuration; it does **not** prove that enforcement has happened. [Official API guide](https://docs.cloud.google.com/billing/docs/how-to/budget-api-spend-cap)

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

**JPY 500/month is a target, not a guaranteed invoice ceiling.** A normal all-service JPY 500 budget is an additional notification only, not a substitute for the cap. Inspect billing Reports by the selected shared project and by service for actual costs, including storage/build/network/taxes. The Run cap does not cover the rest of the billing account.

## Applied budgets and next rollout

- **Run cap:** JPY 400/month, project `121643671058`, service `152E-C115-5142`, gross cost excluding credits, state **CONFIGURED**, no reconciling flag. Budget ID `fe0177db-e81e-494f-a512-4b1e7343ec0f`.
- **Project notification:** JPY 500/month, all services in the same project, net of credits, 50/80/100% notifications, no spendCap. Budget ID `7b29815c-461b-439e-aecd-5abc35379ba9`. This does not stop services.
- The existing account-wide JPY 10,000 budget is unchanged. The JPY 400 cap can stop **all 23 existing Run services**, even before loadings-mcp is deployed. Existing current-month gross usage counts; no enforcement test, cap lift or budget overwrite was performed.

Reverify before every deployment:

```sh
export GOOGLE_CLOUD_PROJECT=stable-century-479407-m7
# Explicitly acknowledged shared-project impact; approved in this session:
export APPROVE_SHARED_PROJECT=stable-century-479407-m7
export BILLING_ACCOUNT_ID=YOUR_APPROVED_JPY_BILLING_ACCOUNT
Rscript --vanilla scripts/spend-cap.R verify
```

The verifier permits only dedicated projects or this specifically acknowledged shared project. It rejects a notification-only budget, wrong scope/currency, unsettled cap, cap > JPY 400, or non-CONFIGURED state. Do not rerun create; the budgets already exist. If enforcement occurs, do not automatically lift it.

Completed under subsequent approval: created the role-free `loadings-mcp-runtime` identity and deployed the new private service. An end-to-end numerical precision defect required one cached repair build; see DEPLOYMENT.md for the image and results. No registry, cross-project grant or project-wide role was added. The following commands describe the completed deployment and must not be blindly rerun.

```sh
export RUNTIME_SERVICE_ACCOUNT=loadings-mcp-runtime@stable-century-479407-m7.iam.gserviceaccount.com
export IMAGE=asia-northeast1-docker.pkg.dev/stable-century-479407-m7/cloud-run-source-deploy/loadings-mcp@sha256:6e4ff45500b6129f7d5d765de309c092ee0d140b15d6e5128fb14add2c3798f8
gcloud iam service-accounts create loadings-mcp-runtime --project stable-century-479407-m7 --display-name='loadings MCP runtime'
# scripts/deploy.sh verifies the cap and asks for deploy before this command:
gcloud run deploy loadings-mcp --project stable-century-479407-m7 --region asia-northeast1 \
  --image "$IMAGE" --service-account "$RUNTIME_SERVICE_ACCOUNT" --no-allow-unauthenticated \
  --port 8080 --concurrency 1 --cpu 1 --memory 512Mi --cpu-throttling --timeout 30 \
  --min 0 --max 1 --min-instances 0 --max-instances 1
```

Immediately before creation, confirm the name is still unused. Test cold start, memory, initialize, tools/list, all four tools/eight methods, invalid input and JSON using `scripts/smoke-remote.R` with an identity token. HTTP/R-client success is separate from manual ChatGPT/Claude success. Stop if the cap cannot be verified; never lift it to complete tests.

Before public approval, add/test pre-parser body limits, an actual computation deadline (killable worker), bounded request admission and failure/recovery tests. These are **not implemented yet**. Cloud Run timeout returns 504 but does not kill computation. In-process throttling resets on restart and does not provide a durable monthly limit. [Timeout behavior](https://docs.cloud.google.com/run/docs/configuring/request-timeout)

Present measured results and remaining risks, obtain separate final approval for anonymous invocation on **only loadings-mcp**, repeat tests anonymously, and only then publish the actual /mcp endpoint and free best-effort service limits on Pages. No public invocation has been enabled.

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

Use built-in Cloud Run Metrics (request count, 4xx/5xx, latency, CPU, memory) and Cloud Billing Reports filtered to project `stable-century-479407-m7`. For monthly request totals, choose metric `run.googleapis.com/request_count`, service `loadings-mcp`, month interval and sum; group by `response_code_class` for errors. Inspect memory after each method/cold start. No uptime polling, custom metrics or paid alert policies are configured yet. Spend-cap emails go to billing admins/project owners automatically. [Run monitoring](https://docs.cloud.google.com/run/docs/monitoring)

Read-only checks after deployment:

```sh
gcloud run services describe loadings-mcp --project stable-century-479407-m7 --region asia-northeast1
gcloud logging read 'resource.type="cloud_run_revision" AND resource.labels.service_name="loadings-mcp" AND severity>=ERROR' --project stable-century-479407-m7 --freshness=24h --limit=100
Rscript --vanilla scripts/spend-cap.R verify
```

Emergency: revoke public reachability by changing **only this service** to internal ingress:

```sh
gcloud run services update loadings-mcp --project stable-century-479407-m7 --region asia-northeast1 --ingress internal
```

Then verify external MCP requests fail. In-flight work may continue; if necessary delete **only this loadings-mcp service** to stop its runtime:

```sh
gcloud run services delete loadings-mcp --project stable-century-479407-m7 --region asia-northeast1
```

Do not disable billing on the shared project or lift a cap automatically. Deleting the service does not remove image/log/build-source storage charges. Restoration needs an approved redeploy or ingress change, valid cost protection and fresh connectivity tests. Spend caps reset monthly and can resume service automatically; emergency internal ingress persists until explicitly changed. Update the site's service status if suspended.
