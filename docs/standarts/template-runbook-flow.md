# FLOW-XX Runbook (Canonical Template)

Status: draft  
Last updated: YYYY-MM-DD  
Scope: operational execution and verification path for FLOW-XX.

## Purpose

This runbook defines the canonical operator path to execute and verify FLOW-XX.

It MUST include:
1. one copy-paste command path,
2. explicit expected outcomes per stage,
3. evidence requirements,
4. troubleshooting actions for common failures.

## In Scope / Out of Scope

In scope:
- runtime/deploy/test actions required to operate FLOW-XX,
- validation checks and evidence collection.

Out of scope:
- implementation details already covered by the flow spec,
- backlog planning (handled in `todo.md`).

## Required Reads

1. `AGENTS.md`
2. `PROJECT_CONTEXT.md`
3. `docs/flows/flow-XX/spec/<FLOW_SPEC_FILE>.md`
4. `docs/flows/flow-XX/todo/todo.md`
5. related runbooks and host docs (if applicable)

## Preconditions

1. Required tools are installed and available in PATH.
2. Required credentials/secrets are configured outside git.
3. Required environment/profile variables are set.
4. Target environment is reachable.

## Canonical Command Path

Run from repo root unless stated otherwise.

```bash
# 1) syntax/contract checks
<command>

# 2) deploy/setup
<command>

# 3) execution
<command>

# 4) verification
<command>
```

## Stage-by-Stage Verification

### FXX-RUN-001 — <stage name>
Goal: <what this stage proves>.

Command:
```bash
<command>
```

Expected:
- RC/exit code policy,
- key observable output markers.

Evidence:
- log file/job id/artifact path.

### FXX-RUN-002 — <stage name>
Goal: <...>

Command:
```bash
<command>
```

Expected:
- ...

Evidence:
- ...

## Troubleshooting Matrix

| Symptom | Likely cause | Action |
| --- | --- | --- |
| `<error>` | `<cause>` | `<fix>` |
| `<error>` | `<cause>` | `<fix>` |

## Evidence Record Format

Use one record per check:

```text
[FLOW-XX][FXX-RUN-00X] <PASS/FAIL>
Date:
Commit/Build:
Observed:
Evidence paths:
Notes:
```

## Maintenance Rules

Update this runbook in the same PR/commit when changing:
1. commands,
2. playbook/workflow names,
3. required env/secrets,
4. acceptance criteria,
5. evidence locations.
