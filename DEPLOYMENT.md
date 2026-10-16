# Publication status — 2026-10-17

Website: https://hiroyukiyamamoto.github.io/loadings-mcp/ . Cloud Run is **deployed privately and passes authenticated MCP tests**. Anonymous access remains disabled; `docs/config.json` intentionally remains null. Public transport safeguards and final publication approval are still required.

## Running service

- Project: `stable-century-479407-m7`; region: `asia-northeast1`.
- Service: `loadings-mcp`; serving revision: `loadings-mcp-00002-ng4` (100% traffic).
- Endpoint: `https://loadings-mcp-121643671058.asia-northeast1.run.app/mcp` — requires a Cloud Run IAM identity token, not a public ChatGPT/Claude endpoint.
- Runtime identity: `loadings-mcp-runtime@stable-century-479407-m7.iam.gserviceaccount.com`. Created under explicit approval; no project roles were granted, and project IAM lookup found none for this identity.
- Service IAM has no anonymous/allAuthenticatedUsers binding. Anonymous MCP POST returned HTTP 403.
- CPU 1; memory 512 MiB; concurrency 1; request-based CPU allocation; timeout 30s; service/revision max 1; minimum 0. Built-in startup CPU boost remains enabled. Native memory distribution sample mean was 53.18% (~272 MiB); this is not peak memory or a maximum-input sizing guarantee.

## Numerical precision correction

The first private deployment using the prior validated image initialized successfully but **failed** the end-to-end demo-to-PCA test. The pinned mcptools structured-content serializer rounded numbers to four decimal places; 29 fasting-metabolome columns became zero/constant. Previous HTTP checks supplied local data and missed that output round trip.

The wrapper now returns full-precision JSON through official `ellmer::ContentText`. No MCP implementation or package internals were patched; loadings and the analysis algorithms are unchanged. Regression tests compare every fasting/whhl input number after HTTP transfer and compare PCA scores and p-values with the local official result. The example input JSON generator also preserves small values. Clients parse `result.content[0].text`; `structuredContent` is intentionally absent.

A single cached repair build succeeded: `4a1269de-3346-46d7-a971-c4690d0e1011`, Tokyo, elapsed about 76s (300s configured deadline). The initial no-rebuild plan was revised because the real deployment test found this defect. No new paid service/API or project role was added for the build. Build/Registry charges are outside the Run cap; actual invoiced build cost is unverified.

Deployed immutable image:

```text
asia-northeast1-docker.pkg.dev/stable-century-479407-m7/cloud-run-source-deploy/loadings-mcp@sha256:6e4ff45500b6129f7d5d765de309c092ee0d140b15d6e5128fb14add2c3798f8
```

PowerShell executed the exact gcloud deployment flags documented in `scripts/deploy.sh`, after running its spend-cap verifier separately. Other 23 Run services were not redeployed or given new IAM policies. The user separately approved their inclusion in the shared project's cap.

## Actual checks

Authenticated test at 2026-10-17 00:18 JST (report also records UTC):

| Check | Result |
| --- | --- |
| Initialize | PASS, negotiated 2025-06-18 |
| tools/list | PASS: demo_data, analyze_pca, analyze_model, analyze_multiset; no arbitrary-code/session tools |
| fasting demo -> PCA | PASS, 10 x 282; source numbers retained; first two variance ratios ~40.10%, 15.49% |
| analyze_model | PASS: OS-PCA, PLS-ROG, PLS-DA, RCCA-DA |
| analyze_multiset | PASS: multiset PLS, multiset PLS-ROG, unsupervised multiset PLS; all four whhl tissue blocks |
| Analysis HTTP duration | ~0.53–1.88s per successful analysis call in this run; not a cold-start or worst-case guarantee |
| Invalid constant-column input | PASS: ok=false, analysis_error |
| Malformed JSON | PASS: HTTP 400 |
| Unknown method / recovery | PASS: -32601; subsequent initialize succeeds |
| Anonymous invocation | PASS: HTTP 403 (private) |
| ChatGPT / Claude Desktop / Claude Code | Manual tests UNVERIFIED; Claude Code CLI unavailable locally |
| Public body/rate/hard computation limits | NOT IMPLEMENTED; anonymous publication remains blocked |
| Invoice / cap enforcement event | UNVERIFIED; cap configuration is verified, not an invoice ceiling |

Scripts: `scripts/smoke-remote.R`, `scripts/check-remote-http.R`. Detailed JSON and measured deployment settings stay in ignored `test-results/`; identity tokens are neither printed nor saved. Local HTTP precision regression and static-site checks also pass. Cloud Run runs the repaired Linux Docker image successfully.

## Cost protection and next steps

The JPY 400 monthly Run cap is CONFIGURED; the JPY 500 project-wide budget is alerts-only. Existing JPY 10,000 account budget is unchanged. **All existing Cloud Run services in this project are included**; existing usage can exhaust the cap. Enforcement delays, other services, storage, networking and taxes prevent a guaranteed JPY 500 total. Never lift a cap automatically to complete a test. See [operations and emergency stop](OPERATIONS.md).

Next: implement and privately test pre-parser body limits, a killable computation deadline, bounded request admission and maximum-input behavior. Then present the tested public configuration and risks for separate final anonymous-access approval. Only after approval and successful anonymous MCP tests should the actual endpoint and free best-effort access terms be placed in the site's config. No public IAM change is part of the completed private-deployment authorization.
