# Standard Dev Process (Todo-Block Mode)

Status: active

This document defines the canonical execution process for flow work.

Core rule:
- implementation is planned and controlled in `docs/flows/flow-XX/todo/todo.md`.
- by default, do not create separate task files for every TODO point.

## 1) Non-negotiable rules

1. Do not edit `PROJECT_TODO_*.md` unless explicitly requested.
2. Keep flow spec and flow todo aligned.
3. Keep flow runbook aligned with flow behavior (`docs/runbooks/runbook-flow-XX.md`).
4. One commit block = one logically complete TODO block (or clearly scoped subset).
5. Run required checks before closing a block.
6. Record acceptance evidence in commit/PR notes.

## 2) Required execution sequence

### Step 1 — Read context first
Read at minimum:
- `AGENTS.md`
- `PROJECT_CONTEXT.md`
- relevant flow spec: `docs/flows/flow-XX/spec/...`
- flow execution plan: `docs/flows/flow-XX/todo/todo.md`
- flow runbook (if exists): `docs/runbooks/runbook-flow-XX.md`

### Step 2 — Select target block in `todo.md`
Pick one block from `todo.md` and execute only that scope.

The block MUST already contain:
- Goal
- Scope
- Required tests/checks
- Acceptance criteria
- Reject conditions

If one of these is missing, update `todo.md` first.

### Step 3 — Implement minimal focused change
- avoid unrelated refactors.
- keep architecture invariants from flow spec.

### Step 4 — Validate
Run the block's required checks.
At minimum for this repo when Java code changed:

```bash
mvn -U test
```

For host/ansible blocks run at least syntax checks unless host execution is required:

```bash
cd host-library-infra/ansible
ansible-playbook -i inventories/hosts.yml playbooks/smoke.yml --syntax-check
```

### Step 5 — Finalize block status
Mark/reflect block progress in `todo.md` (state and notes) if requested by flow owner.

## 3) Canonical block template for `todo.md`

Use this shape for every execution block:

```md
## Block FXX-A — <short name>

### Goal
<clear outcome>

### Scope
- ...

### Required tests/checks
1. ...
2. ...

### Acceptance criteria
- ...

### Reject conditions
- ...
```

## 4) When separate task files are allowed

Create standalone files under `docs/flows/flow-XX/tasks/` only when explicitly requested,
for example:
- external handoff package needed,
- high-risk change requires formal mini-RFC,
- reviewer asks for isolated implementation memo.

Default remains: all execution details stay in `todo.md` blocks.
