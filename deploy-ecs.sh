#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
REPO_NAME="${ECR_REPO:-barakah-app}"
CLUSTER="${ECS_CLUSTER:-barakah-cluster}"
SERVICE="${ECS_SERVICE:-barakah-app-svc}"
CONTAINER="${ECS_CONTAINER:-barakah-app}"

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
TAG="$(git rev-parse --short=7 HEAD)"
IMAGE="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}:${TAG}"

echo "Rendering task definition with ${IMAGE}"
python3 ecs/render_taskdef.py ecs/task-definition.json taskdef-rendered.json "$CONTAINER" "$IMAGE"

TASKDEF_ARN="$(aws ecs register-task-definition --region "$AWS_REGION" \
  --cli-input-json file://taskdef-rendered.json \
  --query 'taskDefinition.taskDefinitionArn' --output text)"
echo "Registered ${TASKDEF_ARN}"

echo "Starting rolling update of ${SERVICE}"
aws ecs update-service --region "$AWS_REGION" --cluster "$CLUSTER" --service "$SERVICE" \
  --task-definition "$TASKDEF_ARN" --query 'service.serviceName' --output text

echo "Waiting for the rolling update to finish..."
aws ecs wait services-stable --region "$AWS_REGION" --cluster "$CLUSTER" --services "$SERVICE"

# If the new version failed, the circuit breaker rolls back and the service
# is stable again, but on the old revision. Catch that and fail the build.
RUNNING="$(aws ecs describe-services --region "$AWS_REGION" --cluster "$CLUSTER" --services "$SERVICE" \
  --query 'services[0].taskDefinition' --output text)"
if [ "$RUNNING" != "$TASKDEF_ARN" ]; then
  echo "Deployment was rolled back. Service is running ${RUNNING}"
  exit 1
fi

echo "Deployed ${IMAGE} to ${SERVICE} (${TASKDEF_ARN})"
