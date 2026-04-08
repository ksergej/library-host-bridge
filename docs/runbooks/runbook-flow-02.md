# FLOW-02 Runbook

Status: active  
Last updated: 2026-04-08  
Scope: host CI/CD execution for z/OS (Ansible + JCL + DB2 + MQ) in FLOW-02.

## Purpose

This runbook defines the canonical operator path for FLOW-02:
1. deploy host artifacts,
2. apply DB2 schema/data,
3. compile/link/bind host program,
4. run optional runtime smoke.

Locked first test scope:
- `LIBSCHEM`
- `LIBDATA`
- source `LIBMQTST.cbl`
- compile via `CBLMQDB2.jcl.j2`
- run via `LIBMQTST.jcl.j2`

MQ correlation rule is invariant and MUST stay unchanged:
- host MQMD: `CorrelId = request MsgId`, then clear `MsgId`,
- Java side selects reply by `JMSCorrelationID = request JMSMessageID`.

## Required Reads

1. `AGENTS.md`
2. `PROJECT_CONTEXT.md`
3. `docs/flows/flow-02/spec/FLOW-02_CICD_HOST.md`
4. `docs/flows/flow-02/todo/todo.md`
5. `host-library-infra/jcl/README_XPLORE_JOBS.md`

## Preconditions

1. z/OS target is reachable over SSH.
2. Inventory and vars are configured:
   - `host-library-infra/ansible/inventories/hosts.yml`
   - `host-library-infra/ansible/inventories/group_vars/zos_xplore.yml`
3. ZOAU Python environment on host is valid (`zoautil_py` import works).
4. MQ/DB2 placeholder datasets and subsystem variables are set in group vars.
5. No secrets are committed to git.

## Canonical Command Path (Local Operator)

From repo root:

```bash
cd host-library-infra/ansible

# 1) syntax checks
ansible-playbook -i inventories/hosts.yml playbooks/library_deploy.yml --syntax-check
ansible-playbook -i inventories/hosts.yml playbooks/smoke.yml --syntax-check

# 2) deploy datasets + members
ansible-playbook -i inventories/hosts.yml playbooks/library_deploy.yml

# 3) DB2 schema and test data
ansible-playbook -i inventories/hosts.yml playbooks/db2_schema.yml
ansible-playbook -i inventories/hosts.yml playbooks/db2_data.yml

# 4) compile/link/bind
ansible-playbook -i inventories/hosts.yml playbooks/compile_host.yml

# 5) optional runtime smoke
ansible-playbook -i inventories/hosts.yml playbooks/run_host.yml

# 6) collect spool/evidence artifacts (run even if previous step failed)
ansible-playbook -i inventories/hosts.yml playbooks/host_collect_artifacts.yml \
  -e artifact_id="$(date +%Y%m%dT%H%M%S)"
```

## GitHub Actions Path (F02-A Contract)

Workflow:
- `.github/workflows/host-ci.yml`

Required repository secrets:
- `ZOS_HOST`
- `ZOS_SSH_USER`
- `ZOS_SSH_PRIVATE_KEY`
- `ZOS_HLQ`

Optional repository variable:
- `ZOS_SSH_PORT` (default `22`)

Execution:
1. `workflow_dispatch`:
   - full path `library_deploy -> db2_schema -> db2_data -> compile_host`
   - optional `run_host` via `run_runtime_smoke=true`.
2. `push` (debug mode):
   - if push includes COBOL changes and no DB2 changes, CI runs
     `library_deploy -> compile_host -> run_host` (without DB2 steps).

How to run `workflow_dispatch` (GitHub UI):
1. Open repository on GitHub.
2. Go to `Actions`.
3. Select workflow `Host CI`.
4. Click `Run workflow`.
5. Select target branch.
6. Optionally set `run_runtime_smoke=true` (to execute `playbooks/run_host.yml`).
7. Click `Run workflow` to start.

## Stage-by-Stage Verification

### F02-RUN-001 — Syntax contract
Goal: ensure playbooks are structurally valid before host execution.

Command:
```bash
cd host-library-infra/ansible
ansible-playbook -i inventories/hosts.yml playbooks/library_deploy.yml --syntax-check
ansible-playbook -i inventories/hosts.yml playbooks/smoke.yml --syntax-check
```

Expected:
- both commands end without syntax errors.

Evidence:
- terminal output with `playbook: ...` lines.

### F02-RUN-002 — Deploy stage
Goal: create datasets and upload COBOL/JCL/SQL members with IBM-1047 conversion.

Command:
```bash
cd host-library-infra/ansible
ansible-playbook -i inventories/hosts.yml playbooks/library_deploy.yml
```

Expected:
- preflight `zoautil_py` check is OK,
- PDS/PDSE datasets are present,
- member uploads succeed.

Evidence:
- Ansible recap and task logs.

### F02-RUN-003 — DB2 schema
Goal: apply schema job successfully.

Command:
```bash
cd host-library-infra/ansible
ansible-playbook -i inventories/hosts.yml playbooks/db2_schema.yml
```

Expected:
- submitted job RC is acceptable (policy in playbook).

Evidence:
- job id + RC from playbook output.

### F02-RUN-004 — DB2 test data
Goal: load test data successfully.

Command:
```bash
cd host-library-infra/ansible
ansible-playbook -i inventories/hosts.yml playbooks/db2_data.yml
```

Expected:
- submitted job RC is acceptable (policy in playbook).

Evidence:
- job id + RC from playbook output.

### F02-RUN-005 — Compile/link/bind
Goal: build host load module `LIBMQTST` from canonical compile job.

Command:
```bash
cd host-library-infra/ansible
ansible-playbook -i inventories/hosts.yml playbooks/compile_host.yml
```

Expected:
- compile job (`CBLMQDB2`) submitted and passes RC policy.

Evidence:
- job ids, RCs, Ansible output.

### F02-RUN-006 — Runtime smoke (optional)
Goal: run host batch runtime check.

Command:
```bash
cd host-library-infra/ansible
ansible-playbook -i inventories/hosts.yml playbooks/run_host.yml
```

Expected:
- runtime job (`LIBMQTST`) submitted and passes RC policy.

Evidence:
- run job id + RC, spool summary.

### F02-RUN-007 — Artifact collection (always)
Goal: persist spool/RC evidence for tracked jobs into deterministic local files.

Command:
```bash
cd host-library-infra/ansible
ansible-playbook -i inventories/hosts.yml playbooks/host_collect_artifacts.yml \
  -e artifact_id="$(date +%Y%m%dT%H%M%S)"
```

Expected:
- artifact directory created,
- `summary.json` created,
- per-job json files or explicit `NOT_FOUND` markers are present.

Evidence:
- `host-library-infra/ansible/artifacts/<artifact_id>/<host>/summary.json`,
- `host-library-infra/ansible/artifacts/<artifact_id>/<host>/jobs/*`.

## Troubleshooting Matrix

| Symptom | Likely cause | Action |
| --- | --- | --- |
| `environment_vars is undefined` | wrong group vars filename/group mapping | ensure inventory group is `zos_xplore` and vars file is `inventories/group_vars/zos_xplore.yml` |
| `zoautil_py not found` | remote Python/ZOAU mismatch | verify `ansible_python_interpreter`, `PYTHONPATH`, `LIBPATH`, `ZOAU_HOME` in group vars |
| `location must be one of data_set, uss, local` | wrong `zos_job_submit.location` value | use lowercase `location: data_set` |
| `unsupported parameter wait` in `zos_job_submit` | old module arguments | use `wait_time_s` and `return_output` |
| JCL member upload fails for name | member name > 8 chars | rename member to max 8 chars (for example `LIBSCHEM`) |
| SQL upload truncation | SQL lines exceed FB/80 | keep SQL PDS as FB/80 and wrap SQL physical lines to <= 80 chars |

## Evidence Record Format

```text
[FLOW-02][F02-RUN-00X] <PASS/FAIL>
Date:
Commit/Build:
Observed:
Evidence paths/log refs:
Notes:
```

## Maintenance Rules

Update this runbook in the same PR/commit when changing:
1. host playbook names or sequence,
2. inventory/vars paths,
3. required CI secrets/variables,
4. RC acceptance policy,
5. evidence collection locations.
