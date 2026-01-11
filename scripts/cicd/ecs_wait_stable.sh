#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/cicd.env" ]]; then
  _orig_cluster="${CLUSTER-__unset__}"
  _orig_service="${SERVICE-__unset__}"
  _orig_region="${REGION-__unset__}"
  _orig_timeout="${TIMEOUT_SECONDS-__unset__}"
  _orig_sleep="${SLEEP_SECONDS-__unset__}"
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/cicd.env"
  [[ "$_orig_cluster" != "__unset__" ]] && CLUSTER="$_orig_cluster"
  [[ "$_orig_service" != "__unset__" ]] && SERVICE="$_orig_service"
  [[ "$_orig_region" != "__unset__" ]] && REGION="$_orig_region"
  [[ "$_orig_timeout" != "__unset__" ]] && TIMEOUT_SECONDS="$_orig_timeout"
  [[ "$_orig_sleep" != "__unset__" ]] && SLEEP_SECONDS="$_orig_sleep"
  unset _orig_cluster _orig_service _orig_region _orig_timeout _orig_sleep
fi

CLUSTER="${CLUSTER:-${1:-}}"
SERVICE="${SERVICE:-${2:-}}"
REGION="${REGION:-${AWS_REGION:-${AWS_DEFAULT_REGION:-}}}"
TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-900}"
SLEEP_SECONDS="${SLEEP_SECONDS:-15}"

if [[ -z "$CLUSTER" || -z "$SERVICE" ]]; then
  echo "Usage: CLUSTER=... SERVICE=... REGION=... $0" >&2
  exit 2
fi
if [[ -z "$REGION" ]]; then
  echo "REGION is required (REGION or AWS_REGION/AWS_DEFAULT_REGION)." >&2
  exit 2
fi

start_ts=$(date +%s)
echo "Waiting for ECS service stability: cluster=$CLUSTER service=$SERVICE region=$REGION"

while true; do
  now_ts=$(date +%s)
  elapsed=$((now_ts - start_ts))
  if (( elapsed > TIMEOUT_SECONDS )); then
    echo "ERROR: Timed out after ${TIMEOUT_SECONDS}s waiting for service stability." >&2
    aws ecs describe-services \
      --cluster "$CLUSTER" \
      --services "$SERVICE" \
      --region "$REGION" \
      --query "services[0].{status:status,desired:desiredCount,running:runningCount,pending:pendingCount,deployments:deployments}" \
      --output json >&2
    aws ecs describe-services \
      --cluster "$CLUSTER" \
      --services "$SERVICE" \
      --region "$REGION" \
      --query "services[0].events[0:5].[createdAt,message]" \
      --output table >&2 || true
    exit 1
  fi

  info=$(aws ecs describe-services \
    --cluster "$CLUSTER" \
    --services "$SERVICE" \
    --region "$REGION" \
    --query "services[0].{desired:desiredCount,running:runningCount,pending:pendingCount,deployments:length(deployments),primary:deployments[?status=='PRIMARY'].rolloutState|[0]}" \
    --output text)

  if [[ -z "$info" || "$info" == "None" ]]; then
    echo "ERROR: Service not found or no data returned." >&2
    exit 1
  fi

  read -r desired running pending deployments primary <<< "$info"
  echo "desired=$desired running=$running pending=$pending deployments=$deployments primary_rollout=$primary elapsed=${elapsed}s"

  if [[ "$deployments" == "1" && "$pending" == "0" && "$running" == "$desired" && "$primary" == "COMPLETED" ]]; then
    echo "Service is stable."
    exit 0
  fi

  sleep "$SLEEP_SECONDS"
done
