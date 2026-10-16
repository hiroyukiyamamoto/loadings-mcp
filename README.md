# loadings MCP

**Multivariate Statistical Analysis for AI Agents**

R-based MCP tools for researchers using [loadings](https://cran.r-project.org/package=loadings). Official `mcptools::mcp_server()` handles HTTP and protocol processing; no custom MCP implementation or arbitrary R execution tool is exposed. The loadings package is used unchanged.

Website: https://hiroyukiyamamoto.github.io/loadings-mcp/ (published through GitHub Actions). **Free public MCP endpoint:** https://loadings-mcp-121643671058.asia-northeast1.run.app/mcp . No sign-up or API key required. Anonymous official R MCP tests pass for all eight analysis methods; manual ChatGPT/Claude tests remain unverified. See [validation status](VALIDATION.md) and [publication status](DEPLOYMENT.md).

## Methods and tools

| Tool | Function |
| --- | --- |
| `demo_data` | Packaged metabolomes: fasting mouse liver (default) or matched whhl rabbit tissues |
| `analyze_pca` | `stats::prcomp()` + `loadings::pca_loading()` |
| `analyze_model` | `os_pca`, `pls_rog`, `pls_da`, or `rcca_da`, each with its official loading test |
| `analyze_multiset` | Multiset PLS, multiset PLS-ROG and unsupervised multiset PLS, with per-block loading tests |

Scores, coefficients, correlation loadings, unadjusted p-values, conditions and warnings are returned as structured JSON. PCA also returns eigenvalues and explained variance ratios. Other methods explicitly report those quantities as unavailable. Every matrix argument uses `{"rows": [[...], [...]]}`; copy demo_data.x directly into analyze_pca.x. See [tool specification](docs/api.md) and [API research](docs/research.md).

JSON objects are carried in standard MCP text content (`result.content[0].text`) using official `ellmer::ContentText`. This preserves full numeric precision; the pinned mcptools structured-content serializer otherwise rounds small metabolite values and p-values to four decimals. Clients using the R MCP API should parse the returned text with `jsonlite::fromJSON(..., simplifyVector=FALSE)`.

## Local setup

Run from this repository root. R >= 4.1 and compilation tools may be needed; Docker uses R 4.5.2.

```sh
Rscript --vanilla scripts/install.R
Rscript --vanilla tests/pca.R
Rscript --vanilla tests/models.R
Rscript --vanilla tests/multiset.R
Rscript --vanilla tests/http.R
Rscript --vanilla R/server.R
```

Dependencies install into `.library/`, isolated from user libraries. loadings is pinned to 0.6.1; mcptools is pinned to the verified upstream commit in `scripts/install.R` because HTTP/session controls must exist. Startup checks the official API. Transitive dependencies currently resolve from CRAN; record installed versions with `scripts/versions.R`. For production, retain the built container digest to reproduce the deployed artifact.

The server binds `0.0.0.0`, uses `PORT` (default 8080), and serves Streamable HTTP at `/mcp`. Upstream mcptools accepts other paths too; `/mcp` is the documented client endpoint. HTTP GET returns 405; use an MCP POST client, not a browser page, to test it. Built-in session discovery tools are explicitly disabled.

The production Docker entrypoint adds nginx HTTP limits before JSON parsing: 2 MiB per body and 60 requests/minute shared across users, with burst 10. Excess requests return 413/429. Only `/mcp` is proxied. Each tool call runs in a disposable R subprocess terminated after 20 seconds; nginx waits up to 25 seconds and Cloud Run up to 30. The direct R development command omits the nginx limits. These controls do not guarantee a total bill ceiling or prevent all denial-of-service traffic.

## Connect clients

Claude Code local development:

```sh
claude mcp add --transport http loadings-mcp http://localhost:8080/mcp
```

After deployment, use the actual service URL plus `/mcp`. In Claude Desktop, add a custom **remote connector** through connector management; do not put a remote URL into a local stdio command configuration. In ChatGPT, use Plugins → Add custom MCP server where your account/workspace permits it, enter the reachable HTTPS endpoint and configure authentication. Availability and organization permissions apply. These clients have not been manually tested in this development session.

Official instructions: [Claude Code](https://code.claude.com/docs/en/mcp), [Claude remote connectors](https://support.claude.com/en/articles/11175166-get-started-with-custom-connectors-using-remote-mcp), [ChatGPT custom MCP servers](https://developers.openai.com/plugins/deploy/connect-chatgpt). Verified 2026-10-16.

The hosted endpoint uses no authentication and does not require OAuth. Its service-level public invocation was explicitly approved after private tests and cost/request safeguards. The deployment script still defaults to private access and never grants anonymous invocation automatically. Free best-effort service: limits are shared and access can pause when cost protection is triggered. Avoid automatic retry loops on 429/5xx.

## Demo and plots

Ask the assistant: “Call demo_data, then analyze_pca with two components. Explain the scores and strongest loadings, distinguishing exploratory p-values from validated findings.”

```sh
Rscript --vanilla examples/generate.R
node tests/site.mjs
```

This creates actual fasting-metabolome PCA input/output and score/loading plots, plus a four-tissue whhl multiset PLS example. `demo_data(dataset="fasting")` returns all 10 samples and 282 metabolites without filtering. `demo_data(dataset="whhl")` returns all 9 matched samples across plasma, liver, heart and brain (619 metabolites total), with the package's group, connection-weight and differential matrices. Use `unsupervised_tau` for unsupervised multiset PLS. Group codes are retained from the package; no group-code-to-treatment mapping is inferred.

Multiset input is a named envelope: `blocks={"sets":[{"name":"plasma","data":{"rows":[...] }}, ...]}`. Rows must represent the same samples in the same order in every block. The first two multiset methods accept one-hot `y`; PLS-ROG also requires `d`. The unsupervised method uses only blocks and a block-by-block tau matrix. See [API specification](docs/api.md) for upstream loading-test dimension constraints.

## Docker

```sh
docker build -t loadings-mcp:local .
docker run --rm -e PORT=8080 -p 8080:8080 loadings-mcp:local
```

The image includes compilers, curl/OpenSSL/XML dependencies and the R packages, and runs as an unprivileged user. No runtime package downloads are required. Input is limited to finite numeric matrices: at most 500 rows, 400 columns and 50,000 cells per matrix. Multiset input allows 2–4 blocks, at most 800 combined variables and 100,000 combined cells. Output is limited by `components` and `max_rows`, with truncation metadata. The upstream HTTP layer parses request bodies before tool-level validation; configure ingress/body limits and access controls for production exposure. No input files or arbitrary URLs are accepted, and sample data is not logged by this project.

## Google Cloud Run — approval required

The user approved retaining project `stable-century-479407-m7`, including the impact on all 23 existing Run services. A JPY 400 monthly Cloud Run spend cap is now CONFIGURED and a separate JPY 500 project-wide alerts-only budget exists. Existing service usage counts toward the cap. JPY 500/month is a target, not a guaranteed ceiling: enforcement is delayed and Build/Registry/Logging/network charges can remain outside the cap. The script requires a freshly verified cap and `APPROVE_SHARED_PROJECT=stable-century-479407-m7` for this acknowledged exception. The role-free runtime identity and guarded public deployment are complete; authenticated and anonymous tests pass. See [operations and cost review](OPERATIONS.md) and [current publication status](DEPLOYMENT.md).

Service: `loadings-mcp`; region: `asia-northeast1`. Prepare an approved Google Cloud project, billing, Artifact Registry repository, Cloud Build/Run APIs and appropriate IAM before these operations. Do not automatically enable services or change public access.

Build and push to your existing approved registry, for example:

```sh
export GOOGLE_CLOUD_PROJECT=YOUR_APPROVED_PROJECT
export IMAGE=YOUR_APPROVED_REGISTRY_IMAGE_TAG
export RUNTIME_SERVICE_ACCOUNT=YOUR_APPROVED_RUNTIME_SERVICE_ACCOUNT
export BILLING_ACCOUNT_ID=YOUR_APPROVED_JPY_BILLING_ACCOUNT
# Required only for the specifically approved shared project:
export APPROVE_SHARED_PROJECT=stable-century-479407-m7
gcloud builds submit --project "$GOOGLE_CLOUD_PROJECT" --tag "$IMAGE" .
# Prefer setting IMAGE to the resulting immutable sha256 digest before deployment.
bash scripts/deploy.sh
```

The deployment script verifies the configured spend cap, requires typing `deploy`, explicitly deploys privately, uses the approved runtime service account, and sets concurrency 1, min instances 0, max instances 1 (both service and revision limits), 1 CPU, 512 MiB memory, request-based CPU allocation and a 30-second timeout. This sizing passed real demos and representative 50,000/100,000-cell boundary tests on Cloud Run; arbitrary inputs and peak memory are not guaranteed. A request timeout does not itself terminate computation. Public invocation requires separately approved safeguards and a service-level IAM change. Do not change other Cloud Run services.

After deployment, get the URL with `gcloud run services describe loadings-mcp --project "$GOOGLE_CLOUD_PROJECT" --region asia-northeast1 --format='value(status.url)'`. Verify tools/list and tools/call using an authenticated MCP client with the actual URL plus `/mcp`. `scripts/smoke-remote.R` supports an existing identity token through an environment variable. A successful deployment alone is not proof of end-to-end client compatibility.

## GitHub Pages

The static English site lives in `docs/`, with no build framework. Its MCP URL is controlled only by `docs/config.json`; the verified public endpoint and no-auth setting are now configured there. Setting the endpoint to null hides the connection URL during suspension.

Pages is configured with **GitHub Actions** as its source following explicit publication authorization on 2026-10-16. The published site uses `docs/`. To publish subsequent approved changes, manually run **Publish GitHub Pages (manual approval required)**. This supplied workflow has no push trigger; it replaces the legacy branch-based deployment. Public URL: https://hiroyukiyamamoto.github.io/loadings-mcp/ . Preview locally with any static HTTP server rooted at `docs/` (the configuration uses fetch).

Optional browser validation with installed Microsoft Edge and Node.js: `node tests/browser.mjs`. It checks desktop and mobile layouts, images, anchors, and screenshots; browser profiles and outputs stay in ignored `test-results/`.

## Validation and scope

The first PCA MVP was tested before adding the other methods. CI checks analysis, official mcptools HTTP discovery/execution, static asset integrity and a Docker HTTP initialization smoke test. See [VALIDATION.md](VALIDATION.md) for actually executed checks and limitations. The algorithms can produce nonfinite test statistics on degenerate data; JSON encodes these as the explicit string `"not_finite"` and matrix metadata counts them. Unavailable fields are omitted with an explanation. Results are exploratory: p-values are not adjusted, and no classifier validation, prediction, or causal claims are provided.

## License and developer

Developer: Hiroyuki Yamamoto. This wrapper/site is MIT licensed. Dependencies retain their own licenses, including loadings (LGPL-3) and mcptools (MIT). See [references](https://cran.r-project.org/web/packages/loadings/loadings.pdf) for the underlying methods.
