# loadings MCP

**Multivariate Statistical Analysis for AI Agents**

R-based MCP tools for researchers using [loadings](https://cran.r-project.org/package=loadings). Official `mcptools::mcp_server()` handles HTTP and protocol processing; no custom MCP implementation or arbitrary R execution tool is exposed. The loadings package is used unchanged.

Website: https://hiroyukiyamamoto.github.io/loadings-mcp/ (published through GitHub Actions). The hosted MCP endpoint is **not deployed**. See [validation status](VALIDATION.md) and [publication status](DEPLOYMENT.md).

## Methods and tools

| Tool | Function |
| --- | --- |
| `demo_data` | Built-in Iris sample rows and one-hot group data |
| `analyze_pca` | `stats::prcomp()` + `loadings::pca_loading()` |
| `analyze_model` | `os_pca`, `pls_rog`, `pls_da`, or `rcca_da`, each with its official loading test |

Scores, coefficients, correlation loadings, unadjusted p-values, conditions and warnings are returned as structured JSON. PCA also returns eigenvalues and explained variance ratios. Other methods explicitly report those quantities as unavailable. Every matrix argument uses `{"rows": [[...], [...]]}`; copy demo_data.x directly into analyze_pca.x. See [tool specification](docs/api.md) and [API research](docs/research.md).

## Local setup

Run from this repository root. R >= 4.1 and compilation tools may be needed; Docker uses R 4.5.2.

```sh
Rscript --vanilla scripts/install.R
Rscript --vanilla tests/pca.R
Rscript --vanilla tests/models.R
Rscript --vanilla tests/http.R
Rscript --vanilla R/server.R
```

Dependencies install into `.library/`, isolated from user libraries. loadings is pinned to 0.6.1; mcptools is pinned to the verified upstream commit in `scripts/install.R` because HTTP/session controls must exist. Startup checks the official API. Transitive dependencies currently resolve from CRAN; record installed versions with `scripts/versions.R`. For production, retain the built container digest to reproduce the deployed artifact.

The server binds `0.0.0.0`, uses `PORT` (default 8080), and serves Streamable HTTP at `/mcp`. Upstream mcptools accepts other paths too; `/mcp` is the documented client endpoint. HTTP GET returns 405; use an MCP POST client, not a browser page, to test it. Built-in session discovery tools are explicitly disabled.

## Connect clients

Claude Code local development:

```sh
claude mcp add --transport http loadings-mcp http://localhost:8080/mcp
```

After deployment, use the actual service URL plus `/mcp`. In Claude Desktop, add a custom **remote connector** through connector management; do not put a remote URL into a local stdio command configuration. In ChatGPT, use Plugins → Add custom MCP server where your account/workspace permits it, enter the reachable HTTPS endpoint and configure authentication. Availability and organization permissions apply. These clients have not been manually tested in this development session.

Official instructions: [Claude Code](https://code.claude.com/docs/en/mcp), [Claude remote connectors](https://support.claude.com/en/articles/11175166-get-started-with-custom-connectors-using-remote-mcp), [ChatGPT custom MCP servers](https://developers.openai.com/plugins/deploy/connect-chatgpt). Verified 2026-10-16.

The server does not implement OAuth. Cloud Run IAM is separate from MCP OAuth: hosted assistants cannot automatically authenticate to a private Cloud Run service. Decide the authentication architecture before production deployment. Public access/IAM must be approved separately; no script grants unauthenticated access.

## Demo and plots

Ask the assistant: “Call demo_data, then analyze_pca with two components. Explain the scores and strongest loadings, distinguishing exploratory p-values from validated findings.”

```sh
Rscript --vanilla examples/generate.R
node tests/site.mjs
```

This creates the actual JSON input, output, score plot and loading plot displayed on the static website. To explore advanced methods, use Iris `y` for PLS-DA/RCCA-DA; define your scientific ordering before using PLS-ROG. See `tests/models.R` for differential matrix examples (synthetic ordering for testing only).

## Docker

```sh
docker build -t loadings-mcp:local .
docker run --rm -e PORT=8080 -p 8080:8080 loadings-mcp:local
```

The image includes compilers, curl/OpenSSL/XML dependencies and the R packages, and runs as an unprivileged user. No runtime package downloads are required. Input is limited to finite numeric matrices: at most 500 rows, 200 columns and 50,000 cells per matrix. Output is limited by `components` and `max_rows`, with truncation metadata. The upstream HTTP layer parses request bodies before tool-level validation; configure ingress/body limits and access controls for production exposure. No input files or arbitrary URLs are accepted, and sample data is not logged by this project.

## Google Cloud Run — approval required

Service: `loadings-mcp`; region: `asia-northeast1`. Prepare an approved Google Cloud project, billing, Artifact Registry repository, Cloud Build/Run APIs and appropriate IAM before these operations. Do not automatically enable services or change public access.

Build and push to your existing approved registry, for example:

```sh
export GOOGLE_CLOUD_PROJECT=YOUR_APPROVED_PROJECT
export IMAGE=YOUR_APPROVED_REGISTRY_IMAGE_TAG
export RUNTIME_SERVICE_ACCOUNT=YOUR_APPROVED_RUNTIME_SERVICE_ACCOUNT
gcloud builds submit --project "$GOOGLE_CLOUD_PROJECT" --tag "$IMAGE" .
# Prefer setting IMAGE to the resulting immutable sha256 digest before deployment.
bash scripts/deploy.sh
```

The deployment script requires typing `deploy`, explicitly deploys privately, uses the approved runtime service account, and sets concurrency 1, min instances 0, max instances 1 (both service and revision limits), 1 CPU, 1 GiB memory, request-based CPU allocation and a 120-second timeout. Public invocation requires a separately approved service-level IAM change. Do not change project-wide IAM or other Cloud Run services.

After deployment, get the URL with `gcloud run services describe loadings-mcp --project "$GOOGLE_CLOUD_PROJECT" --region asia-northeast1 --format='value(status.url)'`. Verify tools/list and tools/call using an authenticated MCP client with the actual URL plus `/mcp`. `scripts/smoke-remote.R` supports an existing identity token through an environment variable. A successful deployment alone is not proof of end-to-end client compatibility.

## GitHub Pages

The static English site lives in `docs/`, with no build framework. Its MCP URL is controlled only by `docs/config.json`; `null` renders an honest pending-deployment message. After actual deployment and connectivity verification, replace null with the verified HTTPS `/mcp` endpoint and commit.

Pages is configured with **GitHub Actions** as its source following explicit publication authorization on 2026-10-16. The published site uses `docs/`. To publish subsequent approved changes, manually run **Publish GitHub Pages (manual approval required)**. This supplied workflow has no push trigger; it replaces the legacy branch-based deployment. Public URL: https://hiroyukiyamamoto.github.io/loadings-mcp/ . Preview locally with any static HTTP server rooted at `docs/` (the configuration uses fetch).

Optional browser validation with installed Microsoft Edge and Node.js: `node tests/browser.mjs`. It checks desktop and mobile layouts, images, anchors, and screenshots; browser profiles and outputs stay in ignored `test-results/`.

## Validation and scope

The first PCA MVP was tested before adding the other methods. CI checks analysis, official mcptools HTTP discovery/execution, static asset integrity and a Docker HTTP initialization smoke test. See [VALIDATION.md](VALIDATION.md) for actually executed checks and limitations. The algorithms can produce nonfinite test statistics on degenerate data; JSON encodes these as the explicit string `"not_finite"` and matrix metadata counts them. Unavailable fields are omitted with an explanation. Results are exploratory: p-values are not adjusted, and no classifier validation, prediction, or causal claims are provided.

## License and developer

Developer: Hiroyuki Yamamoto. This wrapper/site is MIT licensed. Dependencies retain their own licenses, including loadings (LGPL-3) and mcptools (MIT). See [references](https://cran.r-project.org/web/packages/loadings/loadings.pdf) for the underlying methods.
