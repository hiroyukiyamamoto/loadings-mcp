#!/usr/bin/env bash
set -euo pipefail
: "${GOOGLE_CLOUD_PROJECT:?Set GOOGLE_CLOUD_PROJECT explicitly}"
: "${IMAGE:?Set IMAGE to an already built, pushed container image (prefer a sha256 digest)}"
REGION="asia-northeast1"
SERVICE="loadings-mcp"
printf 'Deploy %s to project %s in %s using %s?\n' "$SERVICE" "$GOOGLE_CLOUD_PROJECT" "$REGION" "$IMAGE"
printf 'No IAM or public-access changes are requested. Type deploy to continue: '
read -r answer
[[ "$answer" == "deploy" ]] || exit 1
gcloud run deploy "$SERVICE" --project "$GOOGLE_CLOUD_PROJECT" --region "$REGION" \
  --image "$IMAGE" --port 8080 --concurrency 1 --cpu 1 --memory 1Gi --timeout 120 --max-instances 3
gcloud run services describe "$SERVICE" --project "$GOOGLE_CLOUD_PROJECT" --region "$REGION" --format='value(status.url)'
