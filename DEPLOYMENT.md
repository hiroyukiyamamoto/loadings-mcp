# Publication status — 2026-10-16

**Current release:** the simpler site and metabolome/multiset extension are published and tested. The image below now contains implementation e0a9279, including all four MCP tools and the real fasting/whhl demos. Cloud Run deployment and IAM changes remain unapproved and have not been performed.

## GitHub Pages

Published: https://hiroyukiyamamoto.github.io/loadings-mcp/ .

The repository's Pages source was changed from legacy `main:/` to GitHub Actions under the user's publication request. [Deployment run 38914326566](https://github.com/hiroyukiyamamoto/loadings-mcp/actions/runs/38914326566) succeeded using the existing `docs/` artifact.

Verified on the live site: HTML, CSS, JS, configuration, all three metabolome SVG plots, demo JSON and documentation return HTTP 200. Headless Microsoft Edge checks passed at 1440×1000 and 390×844, including rendered screenshots, no horizontal overflow, loaded images and valid in-page anchors. The site correctly states that the MCP endpoint is pending; `docs/config.json` remains null.

## Google Cloud preparation

Selected current project: `stable-century-479407-m7` (active authenticated owner account). Billing is already linked. Cloud Run, Cloud Build, Artifact Registry and IAM APIs are already enabled; no API activation, billing changes or project-wide IAM changes were performed.

Existing Docker repository: `asia-northeast1-docker.pkg.dev/stable-century-479407-m7/cloud-run-source-deploy`. Only the new `loadings-mcp` image is built. The 23 existing Cloud Run services in asia-northeast1 were inspected and left unchanged; no service named loadings-mcp existed at the preflight check.

Cloud Build: `f877dac5-082d-47f5-95d7-9919f4d6f217`, region asia-northeast1. Source submission is restricted by `.gcloudignore` to the Dockerfile, Docker ignore file, R code and installer; local credentials, R libraries and browser profiles are excluded. The build uses the existing Cloud Build identity and existing source bucket; no permissions were added.

Build result: **SUCCESS**. Immutable image:

```text
asia-northeast1-docker.pkg.dev/stable-century-479407-m7/cloud-run-source-deploy/loadings-mcp@sha256:152a5a0b3a25a50182ed69361db9571e256b0feae97347f0849270323aa39cf9
```

Cloud Run deployment and IAM changes are **pending explicit approval**. The planned runtime identity is a dedicated `loadings-mcp-runtime` service account without project roles. The proposal is to create that identity, deploy loadings-mcp privately using an immutable image digest, and (only if approved) grant `allUsers` the `roles/run.invoker` role on this new service.

Planned limits: service and revision min=0/max=1, concurrency=1, 1 vCPU, 1 GiB RAM, request-based CPU allocation, 120-second request timeout. No existing service is updated.

### Exact commands awaiting approval

These commands have **not** been executed. Creation of the dedicated identity and the new service's IAM changes require approval. No project roles are granted to the runtime identity.

```sh
export GOOGLE_CLOUD_PROJECT=stable-century-479407-m7
export IMAGE=asia-northeast1-docker.pkg.dev/stable-century-479407-m7/cloud-run-source-deploy/loadings-mcp@sha256:152a5a0b3a25a50182ed69361db9571e256b0feae97347f0849270323aa39cf9
export RUNTIME_SERVICE_ACCOUNT=loadings-mcp-runtime@stable-century-479407-m7.iam.gserviceaccount.com

gcloud iam service-accounts create loadings-mcp-runtime \
  --project "$GOOGLE_CLOUD_PROJECT" --display-name='loadings MCP runtime'

# The existing scripts/deploy.sh will execute this command after confirmation:
gcloud run deploy loadings-mcp --project "$GOOGLE_CLOUD_PROJECT" --region asia-northeast1 \
  --image "$IMAGE" --service-account "$RUNTIME_SERVICE_ACCOUNT" --no-allow-unauthenticated \
  --port 8080 --concurrency 1 --cpu 1 --memory 1Gi --cpu-throttling --timeout 120 \
  --min 0 --max 1 --min-instances 0 --max-instances 1

# Only after the private deployment passes authenticated MCP tests:
gcloud run services add-iam-policy-binding loadings-mcp \
  --project "$GOOGLE_CLOUD_PROJECT" --region asia-northeast1 \
  --member=allUsers --role=roles/run.invoker
```

After the final command, repeat the MCP tests anonymously. Only on success set `docs/config.json` to the actual /mcp URL and publish the updated site. Re-check that the service name is unused immediately before creating the service; stop if another deployment has appeared.

## Security and operational limits

The proposed public mode is anonymous HTTPS for a bounded computation service, with no OAuth or API key at the application layer. Arbitrary R execution/session tools are disabled; numeric input and output dimensions are limited. The dedicated runtime identity has no project roles and is not given data-store access.

Maximum instances and concurrency reduce capacity and cost exposure; they are not per-IP rate limiting, complete DoS protection, or a guaranteed spending cap. The upstream transport parses request bodies before analysis input validation. A public attacker can still consume the one instance or send oversized requests. Per-user authentication, a rate-limiting gateway or a load balancer/Cloud Armor would require additional design, permissions and possibly cost; none is silently provisioned here.

Build execution, image storage, requests and data transfer may incur charges even with min=0. Existing billing settings were not changed. No load test is performed against this project.

## Connection validation

Pending a deployed endpoint. `scripts/smoke-remote.R` will check explicit MCP initialization, official mcptools discovery, demo_data, PCA, all four analyze_model methods, all three analyze_multiset methods, and an invalid input. It accepts optional Cloud Run credentials only via `CLOUD_RUN_ID_TOKEN`; output never includes that token.

Claude Code was not found on the local PATH; no Claude Code/Claude Desktop/ChatGPT connection success is claimed. The [official ChatGPT connection guide](https://developers.openai.com/plugins/deploy/connect-chatgpt) was rechecked: connect a reachable HTTPS /mcp endpoint via Plugins → Add custom MCP server, subject to account/workspace permissions and matching authentication.
