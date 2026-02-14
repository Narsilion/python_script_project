#!/usr/bin/env bash
set -euo pipefail

ACCOUNT_ID="436081123286"
REGION="eu-central-1"
REPO="python-script"
TAG="${1:-v1.0}"

IMAGE_URI="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO}:${TAG}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

if docker buildx version >/dev/null 2>&1; then
  docker buildx build --load -t "${IMAGE_URI}" "${PROJECT_ROOT}"
else
  DOCKER_BUILDKIT=0 docker build -t "${IMAGE_URI}" "${PROJECT_ROOT}"
fi

echo "Built image: ${IMAGE_URI}"
