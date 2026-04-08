# FLOW-02 TODO (Host CI/CD Execution Plan)

Status: active  
Updated: 2026-04-08

## 0. Working Model (Locked)

This TODO is the authoritative execution plan for FLOW-02.

Rules:
1. Execution is block-based.
2. Each block already contains scope, checks and acceptance.
3. Separate task docs per TODO item are not required by default.
4. Any implementation drift from spec must be rejected.

Authoritative spec:
- `docs/flows/flow-02/spec/FLOW-02_CICD_HOST.md`

Required context:
- `AGENTS.md`
- `PROJECT_CONTEXT.md`
- `host-library-infra/jcl/README_XPLORE_JOBS.md`
- `docs/runbooks/HOST_SMOKE_AND_DEBUG.md`

## 1. Architecture Invariants (Must Not Regress)

1. Host pipeline scope is limited to `host-library-infra`.
2. MQ correlation rule remains unchanged (CorrelId = MsgId on host side).
3. No secrets are committed in repo.
4. Source uploads to z/OS use explicit `IBM-1047` conversion.
5. SQL members `SCHEMA` / `TESTDATA` stay compatible with FB/80 dataset policy.
6. Compile track is deterministic for minimal scope:
   - `LIBMQTST` via `CBLMQDB2`

## 2. Mandatory Gate For Every Block

Each block is accepted only if all relevant checks pass.

Baseline checks:

```bash
# Ansible syntax validation
cd host-library-infra/ansible
ansible-playbook -i inventories/hosts.yml playbooks/ssh_precheck.yml --syntax-check
ansible-playbook -i inventories/hosts.yml playbooks/library_deploy.yml --syntax-check
ansible-playbook -i inventories/hosts.yml playbooks/smoke.yml --syntax-check
ansible-playbook -i inventories/hosts.yml playbooks/smoke-full.yml --syntax-check
ansible-playbook -i inventories/hosts.yml playbooks/host_collect_artifacts.yml --syntax-check

# Java safety net (run when Java side is touched)
cd ../../
mvn -U test
```

Host runtime checks (when block touches actual host execution):

```bash
cd host-library-infra/ansible
ansible-playbook -i inventories/hosts.yml playbooks/ssh_precheck.yml
ansible-playbook -i inventories/hosts.yml playbooks/library_deploy.yml
ansible-playbook -i inventories/hosts.yml playbooks/db2_schema.yml
ansible-playbook -i inventories/hosts.yml playbooks/db2_data.yml
ansible-playbook -i inventories/hosts.yml playbooks/compile_host.yml
ansible-playbook -i inventories/hosts.yml playbooks/run_host.yml
```

## 3. Existing Baseline (Current Repo State)

Implemented baseline:
- `host-library-infra/ansible/playbooks/ssh_precheck.yml`
- `host-library-infra/ansible/playbooks/library_deploy.yml`
- `host-library-infra/ansible/playbooks/db2_schema.yml`
- `host-library-infra/ansible/playbooks/db2_data.yml`
- `host-library-infra/ansible/playbooks/compile_host.yml`
- `host-library-infra/ansible/playbooks/run_host.yml`
- `host-library-infra/ansible/playbooks/smoke.yml`
- `host-library-infra/ansible/playbooks/smoke-full.yml`
- `host-library-infra/ansible/playbooks/host_collect_artifacts.yml`
- `host-library-infra/ansible/templates/jcl/CBLMQDB2.jcl.j2`
- `host-library-infra/ansible/templates/jcl/LIBSCHEMA.jcl.j2`
- `host-library-infra/ansible/templates/jcl/LIBDATA.jcl.j2`
- `host-library-infra/ansible/templates/jcl/LIBMQTST.jcl.j2`

Locked first test scope:
- `LIBSCHEM`
- `LIBDATA`
- `LIBMQTST.cbl`
- compile: `CBLMQDB2.jcl.j2`
- run: `LIBMQTST.jcl.j2`

Note:
- `LIBMQCIC`/`CBLMQCIC` assets may still exist in repo but are outside this
  first minimal smoke scope.

Known current gaps:
- optional MQSC health checks are not wired into smoke chain yet.

## 4. Atomic Commit Blocks (FLOW-02)

---

## Block F02-A — Lock Host CI Contract in GitHub Actions

Status: done (2026-04-08)

### Goal
Introduce a dedicated host CI workflow that runs Ansible host pipeline steps.

### Scope
- add `.github/workflows/host-ci.yml`,
- set contract for required secrets/vars,
- run host syntax checks and selected playbooks in deterministic order.

### Required tests/checks
1. workflow yaml lint/parse in CI,
2. local `ansible-playbook ... --syntax-check` remains green,
3. no impact on existing `ci.yml` and `deploy.yml` jobs.

### Acceptance criteria
- host workflow exists and is runnable via `workflow_dispatch`,
- required env/secrets are explicitly validated,
- pipeline fails fast on missing config.

### Delivered
- `.github/workflows/host-ci.yml` added as dedicated FLOW-02 host CI workflow.
- Contract checks implemented for required secrets (`ZOS_HOST`, `ZOS_SSH_USER`,
  `ZOS_SSH_PRIVATE_KEY`, `ZOS_HLQ`).
- Connectivity precheck over SSH added before Ansible execution.
- Host Ansible syntax checks and deterministic playbook order are defined.
- Push debug mode added:
  - when push contains COBOL changes and no DB2 changes, CI runs
    `ssh_precheck -> library_deploy -> compile_host -> run_host`
    (without `db2_schema/db2_data`).

### Reject conditions
- workflow depends on hardcoded credentials,
- host job silently skips failed stages,
- collisions with ECS deploy workflow semantics.

---

## Block F02-B — Artifact Collection Layer (Spool + Evidence)

Status: done (2026-04-08)

### Goal
Collect and persist host run evidence for compile/schema/data/run steps.

### Scope
- add `host_collect_artifacts.yml` (or equivalent),
- collect job output artifacts to deterministic folder,
- make collection step runnable even after failures.

### Required tests/checks
1. syntax-check for new playbook,
2. runbook update with artifact paths,
3. one host run verifying files are produced.

### Acceptance criteria
- artifacts include at least job RC and spool evidence,
- paths are documented and stable,
- collection can run independently.

### Delivered
- Added `host-library-infra/ansible/playbooks/host_collect_artifacts.yml`.
- Collection output path standardized:
  `host-library-infra/ansible/artifacts/<artifact_id>/<inventory_host>/`.
- Implemented evidence files:
  - `summary.json`,
  - `jobs/<JOBNAME>-<JOBID>.json`,
  - `jobs/<JOBNAME>-NOT_FOUND.txt` (explicit missing markers).
- Added CI integration in `.github/workflows/host-ci.yml`:
  - artifact collection step with `if: always()`,
  - upload via `actions/upload-artifact`.

### Reject conditions
- artifacts only available on success,
- artifact paths not deterministic,
- evidence missing for failing jobs.

---

## Block F02-C — Runtime Smoke Integration Policy

Status: done (2026-04-08)

### Goal
Define and implement stable policy for `run_host.yml` in smoke chain.

### Scope
- decide default behavior:
  - include run step in `smoke.yml`, or
  - keep optional with explicit flag/doc,
- align runbook and spec with actual behavior.

### Required tests/checks
1. syntax-check after changes,
2. smoke chain executes deterministically in chosen mode,
3. docs reflect exact command sequence.

### Acceptance criteria
- no ambiguity whether runtime smoke is default,
- commands in docs match real playbook chain.

### Delivered
- `smoke.yml` fixed as default policy: `deploy -> db2_schema -> db2_data -> compile`
  (no runtime run by default).
- Added `smoke-full.yml` as explicit full chain:
  `smoke.yml + run_host + host_collect_artifacts`.
- Updated docs/spec/runbook with explicit smoke policy and commands.

### Reject conditions
- `smoke.yml` and docs diverge,
- runtime step toggled implicitly with no contract.

---

## Block F02-D — DB2/MQ Validation Hardening

Status: done (2026-04-08)

### Goal
Strengthen fail-fast checks and validation semantics for host pipeline.

### Scope
- normalize RC thresholds per step,
- optionally parse critical markers from spool,
- standardize error messages for operator diagnosis.

### Required tests/checks
1. negative test path (intentional bad config) fails with clear message,
2. positive path still passes with current baseline,
3. no regression in existing playbooks.

### Acceptance criteria
- each stage has explicit RC/validation contract,
- failures are actionable from logs.

### Delivered
- Added centralized pipeline parameter catalog in
  `inventories/group_vars/zos_xplore.yml`:
  - `pipeline.max_rc.{schema,data,compile,run}`
  - `pipeline.wait_time_s.{schema,data,compile,run}`
  - `pipeline.artifacts.tracked_jobs`
- Updated playbooks to consume centralized thresholds/timeouts:
  - `db2_schema.yml`
  - `db2_data.yml`
  - `compile_host.yml`
  - `run_host.yml`
- Replaced silent `failed_when`-only behavior with explicit fail messages on RC
  policy breaches for actionable diagnostics.

### Reject conditions
- failures swallowed by permissive max_rc,
- no clear signal which stage failed and why.

---

## Block F02-E — Inventory/Vars Security and Portability

### Goal
Make host inventory/vars portable across environments without secret leakage.

### Scope
- split placeholder defaults vs local secure overrides,
- document vault/local override strategy,
- remove any accidental environment-specific constants from tracked files.

### Required tests/checks
1. syntax-check with placeholder vars,
2. local override example validated,
3. docs updated with secure setup steps.

### Acceptance criteria
- repo is safely clonable without secret edits,
- host operators can configure env with clear procedure.

### Reject conditions
- secret-like values in tracked files,
- setup procedure requires undocumented manual guessing.

---

## Block F02-F — End-to-End Host Smoke Scriptability

### Goal
Provide one operator command path for host smoke execution and diagnosis.

### Scope
- standardize command sequence in runbook,
- optionally provide wrapper script/make target,
- include troubleshooting matrix for common failures.

### Required tests/checks
1. command sequence verified from clean shell,
2. troubleshooting section validated against known errors,
3. docs cross-linked from FLOW-02 spec.

### Acceptance criteria
- single run path is copy/paste-ready,
- operator can identify failing stage quickly.

### Reject conditions
- multiple conflicting command recipes,
- missing mapping from error to recovery action.

---

## Block F02-G — Create Canonical FLOW-02 Runbook

### Goal
Create and lock an operational runbook for FLOW-02 with one canonical execution path.

### Scope
- create/update `docs/runbooks/runbook-flow-02.md`,
- include step-by-step host pipeline commands,
- include expected RC/result per step,
- include troubleshooting for the most common failures.

### Required tests/checks
1. all commands in runbook are copy/pastable and align with current playbooks,
2. links from FLOW-02 spec and TODO are valid,
3. syntax-check commands in runbook are verified.

### Acceptance criteria
- runbook exists and is linked from FLOW-02 spec/todo,
- operator can execute flow without reading chat history,
- expected outcomes and failure diagnostics are explicit.

### Reject conditions
- runbook duplicates outdated flow names/paths,
- commands in runbook diverge from actual playbook inventory/paths,
- no troubleshooting section.

## 5. Notes for Control Lane

1. Do not approve a block without evidence from required checks.
2. Keep block granularity small enough for one focused commit.
3. If scope changes, update this TODO block first, then code.
