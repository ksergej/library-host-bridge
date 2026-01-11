#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/cicd.env" ]]; then
  _orig_instance_id="${INSTANCE_ID-__unset__}"
  _orig_region="${REGION-__unset__}"
  _orig_urls="${URLS-__unset__}"
  _orig_smoke_urls="${SMOKE_URLS-__unset__}"
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/cicd.env"
  [[ "$_orig_instance_id" != "__unset__" ]] && INSTANCE_ID="$_orig_instance_id"
  [[ "$_orig_region" != "__unset__" ]] && REGION="$_orig_region"
  [[ "$_orig_urls" != "__unset__" ]] && URLS="$_orig_urls"
  [[ "$_orig_smoke_urls" != "__unset__" ]] && SMOKE_URLS="$_orig_smoke_urls"
  unset _orig_instance_id _orig_region _orig_urls _orig_smoke_urls
fi

INSTANCE_ID="${INSTANCE_ID:-}"
REGION="${REGION:-${AWS_REGION:-${AWS_DEFAULT_REGION:-}}}"

if [[ -z "$INSTANCE_ID" && -n "${1:-}" ]]; then
  INSTANCE_ID="$1"
  shift
fi

if [[ -z "$REGION" && -n "${1:-}" ]]; then
  REGION="$1"
  shift
fi

URLS=("$@")
if [[ ${#URLS[@]} -eq 0 && -n "${URLS:-}" ]]; then
  read -r -a URLS <<< "$URLS"
elif [[ ${#URLS[@]} -eq 0 && -n "${SMOKE_URLS:-}" ]]; then
  read -r -a URLS <<< "$SMOKE_URLS"
fi

if [[ -z "$INSTANCE_ID" || -z "$REGION" || ${#URLS[@]} -eq 0 ]]; then
  echo "Usage: INSTANCE_ID=... REGION=... $0 <url1> [url2 ...]" >&2
  exit 2
fi

commands=(
  "set -euo pipefail"
  "echo 'SSM smoke check on host: '\"\\\$(hostname)\""
)

for url in "${URLS[@]}"; do
  commands+=("echo 'Checking $url'")
  commands+=("curl -fsS --max-time 10 \"$url\" >/dev/null")
  commands+=("echo 'OK $url'")
done

SSM_COMMANDS="$(printf '%s\n' "${commands[@]}")"
json=$(python3 - <<'PY'
import json
import os
commands = os.environ["SSM_COMMANDS"].splitlines()
print(json.dumps(commands))
PY
)

command_id=$(aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --region "$REGION" \
  --document-name "AWS-RunShellScript" \
  --comment "cicd smoke curl" \
  --parameters "commands=$json" \
  --query "Command.CommandId" \
  --output text)

echo "SSM CommandId: $command_id"

aws ssm wait command-executed \
  --command-id "$command_id" \
  --instance-id "$INSTANCE_ID" \
  --region "$REGION"

status=$(aws ssm get-command-invocation \
  --command-id "$command_id" \
  --instance-id "$INSTANCE_ID" \
  --region "$REGION" \
  --query "Status" \
  --output text)

aws ssm get-command-invocation \
  --command-id "$command_id" \
  --instance-id "$INSTANCE_ID" \
  --region "$REGION" \
  --query "{Status:Status,Stdout:StandardOutputContent,Stderr:StandardErrorContent}" \
  --output json

if [[ "$status" != "Success" ]]; then
  echo "ERROR: SSM command status is $status" >&2
  exit 1
fi
