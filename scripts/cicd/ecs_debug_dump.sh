#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/cicd.env" ]]; then
  _orig_cluster="${CLUSTER-__unset__}"
  _orig_service="${SERVICE-__unset__}"
  _orig_region="${REGION-__unset__}"
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/cicd.env"
  [[ "$_orig_cluster" != "__unset__" ]] && CLUSTER="$_orig_cluster"
  [[ "$_orig_service" != "__unset__" ]] && SERVICE="$_orig_service"
  [[ "$_orig_region" != "__unset__" ]] && REGION="$_orig_region"
  unset _orig_cluster _orig_service _orig_region
fi

CLUSTER="${CLUSTER:-${1:-}}"
SERVICE="${SERVICE:-${2:-}}"
REGION="${REGION:-${AWS_REGION:-${AWS_DEFAULT_REGION:-}}}"

if [[ -z "$CLUSTER" || -z "$SERVICE" ]]; then
  echo "Usage: CLUSTER=... SERVICE=... REGION=... $0" >&2
  exit 2
fi
if [[ -z "$REGION" ]]; then
  echo "REGION is required (REGION or AWS_REGION/AWS_DEFAULT_REGION)." >&2
  exit 2
fi

echo "ECS service summary"
aws ecs describe-services \
  --cluster "$CLUSTER" \
  --services "$SERVICE" \
  --region "$REGION" \
  --query "services[0].{status:status,desired:desiredCount,running:runningCount,pending:pendingCount,taskDefinition:taskDefinition}" \
  --output table

echo "Recent ECS service events"
aws ecs describe-services \
  --cluster "$CLUSTER" \
  --services "$SERVICE" \
  --region "$REGION" \
  --query "services[0].events[0:10].[createdAt,message]" \
  --output table

running_tasks=$(aws ecs list-tasks \
  --cluster "$CLUSTER" \
  --service-name "$SERVICE" \
  --desired-status RUNNING \
  --region "$REGION" \
  --query "taskArns[]" \
  --output text)

if [[ -n "$running_tasks" ]]; then
  echo "Running tasks"
  aws ecs describe-tasks \
    --cluster "$CLUSTER" \
    --tasks $running_tasks \
    --region "$REGION" \
    --query "tasks[].{taskArn:taskArn,lastStatus:lastStatus,health:healthStatus,container:containers[0].name,reason:stoppedReason}" \
    --output table
else
  echo "No running tasks found."
fi

stopped_tasks=$(aws ecs list-tasks \
  --cluster "$CLUSTER" \
  --service-name "$SERVICE" \
  --desired-status STOPPED \
  --max-items 5 \
  --region "$REGION" \
  --query "taskArns[]" \
  --output text)

if [[ -n "$stopped_tasks" ]]; then
  echo "Recent stopped tasks"
  aws ecs describe-tasks \
    --cluster "$CLUSTER" \
    --tasks $stopped_tasks \
    --region "$REGION" \
    --query "tasks[].{taskArn:taskArn,lastStatus:lastStatus,stopCode:stopCode,stoppedReason:stoppedReason,exitCode:containers[0].exitCode,reason:containers[0].reason}" \
    --output table
else
  echo "No stopped tasks found."
fi
