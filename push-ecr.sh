#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
REPO_NAME="${ECR_REPO:-barakah-app}"

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
IMAGE="${REGISTRY}/${REPO_NAME}"
TAG="$(git rev-parse --short=7 HEAD)"

# Tags are immutable, so don't try to push the same commit twice
if aws ecr describe-images --region "$AWS_REGION" --repository-name "$REPO_NAME" \
     --image-ids imageTag="$TAG" >/dev/null 2>&1; then
  echo "Image ${IMAGE}:${TAG} already in ECR, skipping push"
  exit 0
fi

echo "Building ${IMAGE}:${TAG}"
docker build -t "${IMAGE}:${TAG}" .

echo "Logging in to ECR"
aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "$REGISTRY"

echo "Pushing ${IMAGE}:${TAG}"
docker push "${IMAGE}:${TAG}"

docker logout "$REGISTRY"
docker rmi "${IMAGE}:${TAG}" || true
echo "Pushed ${IMAGE}:${TAG} to ECR"
