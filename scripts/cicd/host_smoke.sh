#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ANSIBLE_DIR="$REPO_ROOT/host-library-infra/ansible"
INVENTORY_FILE="${HOST_SMOKE_INVENTORY:-inventories/hosts.yml}"

usage() {
  cat <<'EOF'
Usage:
  host_smoke.sh [--smoke|--full]

Canonical wrapper for FLOW-02 host smoke execution.

Modes:
  --smoke   Run deploy + DB2 + compile + optional runtime smoke (default).
  --full    Run smoke plus artifact collection.

Optional environment overrides:
  RUN_RUNTIME_SMOKE=true|false|auto
  RUN_RUNTIME_SKIP_DB2=true|false|auto
  HOST_SMOKE_ARTIFACT_ID=<id>   (used in --full mode)
EOF
}

mode="smoke"
if [[ $# -gt 0 ]]; then
  case "$1" in
    --smoke|-s)
      mode="smoke"
      shift
      ;;
    --full|-f)
      mode="full"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
fi

if [[ $# -gt 0 ]]; then
  echo "ERROR: Unexpected extra arguments: $*" >&2
  usage >&2
  exit 2
fi

cd "$ANSIBLE_DIR"

ansible_args=("-i" "$INVENTORY_FILE")
if [[ -n "${RUN_RUNTIME_SMOKE:-}" ]]; then
  ansible_args+=("-e" "run_runtime_smoke=${RUN_RUNTIME_SMOKE}")
fi
if [[ -n "${RUN_RUNTIME_SKIP_DB2:-}" ]]; then
  ansible_args+=("-e" "run_runtime_skip_db2=${RUN_RUNTIME_SKIP_DB2}")
fi

echo "Running FLOW-02 host smoke mode=${mode}"
if [[ "$mode" == "full" ]]; then
  if [[ -n "${HOST_SMOKE_ARTIFACT_ID:-}" ]]; then
    ansible_args+=("-e" "artifact_id=${HOST_SMOKE_ARTIFACT_ID}")
  fi
  ansible-playbook "${ansible_args[@]}" playbooks/smoke-full.yml
else
  ansible-playbook "${ansible_args[@]}" playbooks/smoke.yml
fi
