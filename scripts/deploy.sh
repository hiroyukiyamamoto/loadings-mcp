#!/usr/bin/env bash
set -euo pipefail
: "${GOOGLE_CLOUD_PROJECT:?Set GOOGLE_CLOUD_PROJECT explicitly}"
: "${IMAGE:?Set IMAGE to an already built, pushed container image (prefer a sha256 digest)}"
: "${RUNTIME_SERVICE_ACCOUNT:?Set the approved least-privilege runtime service account}"
REGION="asia-northeast1"
SERVICE="loadings-mcp"
printf 'Deploy %s to project %s in %s using %s?\n' "$SERVICE" "$GOOGLE_CLOUD_PROJECT" "$REGION" "$IMAGE"
printf 'Runtime identity: %s. Initial deployment is private. Type deploy to continue: ' "$RUNTIME_SERVICE_ACCOUNT"
read -r answer
[[ "$answer" == "deploy" ]] || exit 1
gcloud run deploy "$SERVICE" --project "$GOOGLE_CLOUD_PROJECT" --region "$REGION" \
  --image "$IMAGE" --service-account "$RUNTIME_SERVICE_ACCOUNT" --no-allow-unauthenticated \
  --port 8080 --concurrency 1 --cpu 1 --memory 1Gi --cpu-throttling --timeout 120 \
  --min 0 --max 1 --min-instances 0 --max-instances 1
gcloud run services describe "$SERVICE" --project "$GOOGLE_CLOUD_PROJECT" --region "$REGION" --format='value(status.url)'
