# Publication status — 2026-10-17

**Public and verified without authentication.** Website: https://hiroyukiyamamoto.github.io/loadings-mcp/ .

MCP endpoint: **https://loadings-mcp-121643671058.asia-northeast1.run.app/mcp** . Streamable HTTP; no sign-up, API key or OAuth required. Manual ChatGPT/Claude connection tests remain unverified.

## Running configuration

| Setting | Value |
| --- | --- |
| Project / region | stable-century-479407-m7 / asia-northeast1 |
| Service / revision | loadings-mcp / loadings-mcp-00003-nbv, 100% traffic |
| Identity | loadings-mcp-runtime@stable-century-479407-m7.iam.gserviceaccount.com, no project roles granted |
| Access | allUsers -> roles/run.invoker on this service only; no project-wide public grant |
| Resources | 1 CPU, 512 MiB; request-based CPU allocation; startup CPU boost enabled |
| Scaling | minimum 0, service/revision maximum 1, concurrency 1 |
| Time limits | worker killed after 20s; proxy response timeout 25s; Run request timeout 30s |
| HTTP limits | body <=2 MiB; shared 60 requests/minute per instance, burst 10; only /mcp proxied |
| Cost protection | JPY 400/month Run cap CONFIGURED; separate JPY 500/month project alerts-only budget |

The user explicitly approved using the shared project, including the cap's effect on the existing 23 services, then private deployment and finally public access. Only loadings-mcp was created/deployed and given anonymous invocation; other service configurations/IAM were not changed. The cap itself applies to all Cloud Run usage in this project.

Deployed image:

```text
asia-northeast1-docker.pkg.dev/stable-century-479407-m7/cloud-run-source-deploy/loadings-mcp@sha256:e5459735ca1517992fab4e3af031027187cbb7d7bf73e75811f96d5d23c65525
```

Guarded image build `339abc73-567e-445f-8bde-71cd590c15d0` succeeded in about 97s, with a 300s deadline and existing cache. No new Google paid service was introduced; nginx runs in the same container. Registry/Build charges remain outside the Run cap. Actual invoice costs are unverified.

## Verification

Anonymous official R MCP client test: 2026-10-17 00:39 JST, negotiated protocol 2025-06-18. Detailed reports stay in ignored test-results files; no tokens are printed or saved.

| Check | Result |
| --- | --- |
| Initialize / tools/list | PASS; exactly demo_data, analyze_pca, analyze_model, analyze_multiset |
| fasting demo -> PCA | PASS, 10 samples x 282 metabolites, full numeric precision; variance ratios ~40.10%, 15.49% |
| Single-dataset models | PASS: OS-PCA, PLS-ROG, PLS-DA, RCCA-DA |
| Multiset models | PASS: multiset PLS, multiset PLS-ROG, unsupervised multiset PLS, all four whhl tissues |
| Invalid constant column | PASS: structured analysis_error |
| Anonymous invocation | PASS: HTTP 200 |
| Invalid JSON / unknown method | PASS: HTTP 400 / MCP -32601; subsequent initialize recovers |
| Body / request rate | PASS on the actual guarded endpoint: HTTP 413 / 429 and recovery after cooldown |
| Worker deadline | PASS locally and in Linux CI: a long-running child is terminated, arbitrary dispatch rejected, subsequent PCA succeeds |
| Upper input boundaries | All 8 methods returned successful JSON at 50,000 single-matrix or 100,000 combined multiset cells; representative boundary cases, not every shape |
| Memory | Guarded revision distribution sample means up to ~62.6% (~321 MiB) during private boundary checks; not a peak guarantee |
| Linux R / Docker CI | PASS: [run 38924893476](https://github.com/hiroyukiyamamoto/loadings-mcp/actions/runs/38924893476), including worker and nginx body/rate tests |
| Manual ChatGPT / Claude | UNVERIFIED; Claude Code CLI unavailable locally |

Anonymous demo analysis calls took about 1.33–5.29s in the official R client. Boundary request timings also include client JSON encoding/upload; they are distinct from the worker's computation deadline. Rate counters reset on instance replacement, and Cloud Run maximum instances is not an absolute bill ceiling.

Scripts: scripts/smoke-remote.R, scripts/check-remote-http.R, scripts/check-capacity.R, scripts/check-limits.R, tests/worker.R. Use MCP_ENDPOINT and omit CLOUD_RUN_ID_TOKEN for public tests. The capacity script uses raw HTTP to avoid expensive large-schema conversion in the official R client; the demo suite tests the official client separately.

## Numerical precision repair

The first private image initialized but failed demo-to-PCA: pinned mcptools rounded ordinary structured-content numbers to four decimals, making 29 fasting columns zero/constant. This was corrected with official ellmer::ContentText carrying full-precision JSON. Clients parse result.content[0].text; structuredContent is intentionally absent. All fasting/whhl input values and PCA scores/p-values now have HTTP regression tests. loadings and the analysis algorithms were not modified. The cached repair build before the guarded release was 4a1269de-3346-46d7-a971-c4690d0e1011 (~76s).

## Costs and emergency stop

**JPY 500/month is a target, not a guaranteed total invoice cap.** JPY 400 is the Cloud Run stop threshold across this shared project's existing and new services; JPY 500 is a notification only. Enforcement is delayed, in-flight usage can finish, and Build/Registry/Logging/network/tax charges can remain. The existing JPY 10,000 account-wide notification was left unchanged. Antigravity's AI plan/credits are outside this Run cap.

To remove public access from only this service:

```sh
gcloud run services remove-iam-policy-binding loadings-mcp --project stable-century-479407-m7 --region asia-northeast1 --member=allUsers --role=roles/run.invoker
```

Then verify anonymous requests are rejected. For further isolation/deletion procedures and budget IDs, see [OPERATIONS.md](OPERATIONS.md). Never automatically lift an enforced spend cap.
