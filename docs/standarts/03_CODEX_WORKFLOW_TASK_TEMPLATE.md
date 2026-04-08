# CODEX WORKFLOW PACKET — Todo-Block Mode Template

Status: active

Use this template when execution is controlled via `docs/flows/flow-XX/todo/todo.md`
blocks (not separate task docs per TODO item).

## 1) Required reads before work

1. `AGENTS.md`
2. `PROJECT_CONTEXT.md`
3. flow spec: `docs/flows/flow-XX/spec/...`
4. flow execution plan: `docs/flows/flow-XX/todo/todo.md`
5. flow runbook (if available): `docs/runbooks/runbook-flow-XX.md`

## 2) Default Definition of Done

1. Implement one selected TODO block (or explicitly scoped subset).
2. Meet all checks listed in that block.
3. Keep behavior aligned with flow spec invariants.
4. Provide full diff and validation outputs requested by owner.

## 3) Copy/paste execution request template

```text
Task: FLOW-XX Block Execution

Read first:
- AGENTS.md
- PROJECT_CONTEXT.md
- docs/flows/flow-XX/spec/<SPEC_FILE>.md
- docs/flows/flow-XX/todo/todo.md
- docs/runbooks/runbook-flow-XX.md

Target block:
- <Block ID, e.g. FXX-A>

Rules:
- Do not modify PROJECT_TODO_*.md.
- Use only the block scope from todo.md.
- Keep architecture invariants from flow spec.
- Before apply: show full diff.
- After apply: run required checks and show results.

Acceptance:
- Block acceptance criteria satisfied.
- Block reject conditions not triggered.
```

## 4) Canonical TODO block shape

```md
## Block FXX-A — <short name>

### Goal
...

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

## 5) Notes

- `docs/flows/flow-XX/tasks/` is optional and used only by explicit request.
- By default, all required implementation details and criteria stay in
  `docs/flows/flow-XX/todo/todo.md`.
