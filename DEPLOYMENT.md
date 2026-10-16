# Publication status — 2026-10-16

## GitHub Pages

Published: https://hiroyukiyamamoto.github.io/loadings-mcp/ .

The repository's Pages source was changed from legacy `main:/` to GitHub Actions under the user's publication request. [Deployment run 38910609509](https://github.com/hiroyukiyamamoto/loadings-mcp/actions/runs/38910609509) succeeded using the existing `docs/` artifact.

Verified on the live site: HTML, CSS, JS, configuration, both SVG plots, demo JSON and documentation return HTTP 200. Headless Microsoft Edge checks passed at 1440×1000 and 390×844, including rendered screenshots, no horizontal overflow, loaded images and valid in-page anchors. The site correctly states that the MCP endpoint is pending; `docs/config.json` remains null.

## Google Cloud preparation

Selected current project: `stable-century-479407-m7` (active authenticated owner account). Billing is already linked. Cloud Run, Cloud Build, Artifact Registry and IAM APIs are already enabled; no API activation, billing changes or project-wide IAM changes were performed.

Existing Docker repository: `asia-northeast1-docker.pkg.dev/stable-century-479407-m7/cloud-run-source-deploy`. Only the new `loadings-mcp` image is built. The 23 existing Cloud Run services in asia-northeast1 were inspected and left unchanged; no service named loadings-mcp existed at the preflight check.

Cloud Build: `38f54dcf-a949-4090-988b-d883ae701654`, region asia-northeast1. Source submission is restricted by `.gcloudignore` to the Dockerfile, Docker ignore file, R code and installer; local credentials, R libraries and browser profiles are excluded. The build uses the existing Cloud Build identity and existing source bucket; no permissions were added.

Cloud Run deployment and IAM changes are **pending explicit approval**. The planned runtime identity is a dedicated `loadings-mcp-runtime` service account without project roles. The proposal is to create that identity, deploy loadings-mcp privately using an immutable image digest, and (only if approved) grant `allUsers` the `roles/run.invoker` role on this new service.

Planned limits: service and revision min=0/max=1, concurrency=1, 1 vCPU, 1 GiB RAM, request-based CPU allocation, 120-second request timeout. No existing service is updated.

## Security and operational limits

The proposed public mode is anonymous HTTPS for a bounded computation service, with no OAuth or API key at the application layer. Arbitrary R execution/session tools are disabled; numeric input and output dimensions are limited. The dedicated runtime identity has no project roles and is not given data-store access.

Maximum instances and concurrency reduce capacity and cost exposure; they are not per-IP rate limiting, complete DoS protection, or a guaranteed spending cap. The upstream transport parses request bodies before analysis input validation. A public attacker can still consume the one instance or send oversized requests. Per-user authentication, a rate-limiting gateway or a load balancer/Cloud Armor would require additional design, permissions and possibly cost; none is silently provisioned here.

Build execution, image storage, requests and data transfer may incur charges even with min=0. Existing billing settings were not changed. No load test is performed against this project.

## Connection validation

Pending a deployed endpoint. `scripts/smoke-remote.R` will check explicit MCP initialization, official mcptools discovery, demo_data, PCA, all four analyze_model methods and an invalid input. It accepts optional Cloud Run credentials only via `CLOUD_RUN_ID_TOKEN`; output never includes that token.

Claude Code was not found on the local PATH; no Claude Code/Claude Desktop/ChatGPT connection success is claimed. The [official ChatGPT connection guide](https://developers.openai.com/plugins/deploy/connect-chatgpt) was rechecked: connect a reachable HTTPS /mcp endpoint via Plugins → Add custom MCP server, subject to account/workspace permissions and matching authentication.
