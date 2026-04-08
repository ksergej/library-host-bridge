# FLOW-02 — CI/CD Host Pipeline (Ansible + JCL on IBM Z Xplore)

Status: active  
Last updated: 2026-04-08  
Scope: host-only pipeline (`host-library-infra`) for z/OS COBOL/MQ/DB2 delivery and smoke execution.

## 1) Purpose

This flow defines the canonical host delivery pipeline currently implemented in this repo:

1. Prepare datasets and upload host assets (COBOL/JCL/SQL) to z/OS.
2. Apply DB2 schema and test data.
3. Compile/link/bind host programs through JCL.
4. Optionally run host batch program for runtime smoke.

Locked minimal test scope (phase-1):
- COBOL source: `LIBMQTST.cbl`
- DB2 jobs: `LIBSCHEM`, `LIBDATA`
- Compile job/template: `CBLMQDB2` / `CBLMQDB2.jcl.j2`
- Run job/template: `LIBMQTST` / `LIBMQTST.jcl.j2`

The flow is implemented with Ansible (`ibm.ibm_zos_core`) and JCL templates in
`host-library-infra/ansible`.

## 2) Current repo structure (as-is)

```text
host-library-infra/
  cobol/
    LIBMQTST.cbl
    LIBMQCIC.cbl              # present in repo, out of minimal scope
    LIBLOAN.cpy
  db2/
    schema.sql
    testdata.sql
  jcl/
    CBLMQDB2.jcl
    CBLMQCIC.jcl              # present in repo, out of minimal scope
    LIBMQTST.jcl
    LIBMQTSTC.jcl
    README_XPLORE_JOBS.md
  ansible/
    ansible.cfg
    inventories/
      hosts.yml
      group_vars/
        zos_xplore.yml
    templates/jcl/
      CBLMQDB2.jcl.j2
      CBLMQCIC.jcl.j2         # present in repo, out of minimal scope
      LIBSCHEMA.jcl.j2
      LIBDATA.jcl.j2
      LIBMQTST.jcl.j2
      LIBMQTSTC.jcl.j2
      BINDPLAN.jcl.j2
    playbooks/
      ssh_precheck.yml
      library_deploy.yml
      db2_schema.yml
      db2_data.yml
      compile_host.yml
      run_host.yml
      host_collect_artifacts.yml
      smoke.yml
      smoke-full.yml
      library_tests.yml
```

Notes:
- Current GitHub Actions workflows include:
  - `.github/workflows/ci.yml`
  - `.github/workflows/deploy.yml` (ECS deployment)
  - `.github/workflows/host-ci.yml` (host pipeline contract for FLOW-02)
- Core GitHub actions are pinned to Node24-compatible majors:
  - `actions/checkout@v5`,
  - `actions/setup-java@v5`,
  - `actions/setup-python@v6`,
  - `actions/upload-artifact@v5`.
- Host inventory/group vars are under `host-library-infra/ansible/inventories`.
- `host-ci.yml` has two execution modes:
  - `workflow_dispatch`: full path
    `ssh_precheck -> deploy -> db2_schema -> db2_data -> compile -> run_host`
    where runtime mode resolution is:
    input `run_runtime_smoke` (`auto|true|false`) > `pipeline.run_runtime_smoke_default`.
    DB2 mode resolution:
    input `run_runtime_skip_db2` (`auto|true|false`) > `pipeline.run_runtime_skip_db2`.
  - `push` with COBOL-only changes (without DB2 changes): debug path
    `ssh_precheck -> deploy -> compile -> run` (DB2 steps skipped),
    and `run_host` follows `pipeline.run_runtime_smoke_default`.

## 3) Inputs and configuration

Primary host config source:
- `host-library-infra/ansible/inventories/group_vars/zos_xplore.yml`

Key variable groups currently used:
- SSH/runtime: `ansible_user`, `ansible_port`, `ansible_python_interpreter`,
  `environment_vars`.
- Dataset naming: `hlq`, `db2.dbrmlib`.
- DB2: `db2.subsystem`, `db2.plan`, `db2.qualifier`, `db2.loadlib`,
  `db2.exitlib`, `db2.tablespace`.
- MQ: `mq.qmgr`, `mq.request_queue`, `mq.reply_queue`, `mq.wait_ms`,
  `mq.loadlib`, `mq.cobcopylib`.
- Compiler/runtime libs: `cobol.compiler_loadlib`, `le.runlib`, `le.runlib2`,
  `le.linklib`, `cics.loadlib`, `cics.copylib`.
- Pipeline control catalog (`pipeline.*`):
  - `pipeline.run_runtime_ssh_precheck`
  - `pipeline.run_runtime_skip_db2`
  - `pipeline.max_rc.{schema,data,compile,run}`
  - `pipeline.wait_time_s.{schema,data,compile,run}`
  - `pipeline.run_runtime_smoke_default`
  - `pipeline.collect_artifacts_default`
  - `pipeline.artifacts.tracked_jobs`

## 4) Canonical pipeline steps

### Step A — SSH precheck

Playbook: `host-library-infra/ansible/playbooks/ssh_precheck.yml`

- Runs minimal host handshake over SSH (`SSH_OK`, `whoami`, `pwd`).
- Uses pipeline switches:
  - `pipeline.run_runtime_ssh_precheck`
- Fails fast on non-zero RC.

### Step B — deploy datasets and sources

Playbook: `host-library-infra/ansible/playbooks/library_deploy.yml`

What it does:
- Preflight check: verifies `zoautil_py` import on host.
- Ensures datasets:
  - `{{ hlq }}.CBL` (PDS FB/80)
  - `{{ hlq }}.JCL` (PDS)
  - `{{ hlq }}.LOAD` (PDSE)
  - `{{ db2.dbrmlib }}` (PDS)
  - `{{ hlq }}.SQL` (PDS FB/80)
- Uploads COBOL source/copybook (`IBM-1047` conversion).
- Renders compile job locally (`CBLMQDB2`) and uploads member.
- Uploads run/schema/data JCL template members.
- Uploads SQL members:
  - `{{ hlq }}.SQL(SCHEMA)`
  - `{{ hlq }}.SQL(TESTDATA)`

### Step C — DB2 schema

Playbook: `host-library-infra/ansible/playbooks/db2_schema.yml`

- Submits `{{ hlq }}.JCL(LIBSCHEM)` only when effective DB2 skip flag is false.
- Requires `RC == 0`.

### Step D — DB2 test data

Playbook: `host-library-infra/ansible/playbooks/db2_data.yml`

- Submits `{{ hlq }}.JCL(LIBDATA)` only when effective DB2 skip flag is false.
- Requires `RC == 0`.

### Step E — compile/link/bind host program

Playbook: `host-library-infra/ansible/playbooks/compile_host.yml`

- Submits compile member:
  - `{{ hlq }}.JCL(CBLMQDB2)` for `LIBMQTST`
- Current acceptance in playbook: `max_rc = 8`.

### Step F — optional run smoke

Playbook: `host-library-infra/ansible/playbooks/run_host.yml`

- Submits `{{ hlq }}.JCL(LIBMQTST)` only when effective runtime flag is true.
- Requires `RC == 0`.
- Effective runtime flag resolution:
  - explicit `run_runtime_smoke` (if provided and not `auto`) wins,
  - otherwise `pipeline.run_runtime_smoke_default` is used.

Important:
- `smoke.yml` includes `run_host`, but run is conditional by the effective flag.
- `smoke-full.yml` is explicit full path:
  `smoke.yml + host_collect_artifacts`.

### Step G — artifact collection (spool/evidence)

Playbook: `host-library-infra/ansible/playbooks/host_collect_artifacts.yml`

- Collects tracked job evidence (`LIBSCHEM`, `LIBDATA`, `CBLMQDB2`,
  `LIBMQTST`) into deterministic local path:
  - `host-library-infra/ansible/artifacts/<artifact_id>/<inventory_host>/`
- Writes:
  - `summary.json` (job index and collection metadata),
  - per-job spool/output json under `jobs/`,
  - `*-NOT_FOUND.txt` markers for missing jobs.
- Runnable independently and intended to be executed even after failed smoke.

## 5) Standard commands

From repo root:

```bash
ansible-playbook -i host-library-infra/ansible/inventories/hosts.yml \
  host-library-infra/ansible/playbooks/ssh_precheck.yml

ansible-playbook -i host-library-infra/ansible/inventories/hosts.yml \
  host-library-infra/ansible/playbooks/library_deploy.yml

ansible-playbook -i host-library-infra/ansible/inventories/hosts.yml \
  host-library-infra/ansible/playbooks/db2_schema.yml

ansible-playbook -i host-library-infra/ansible/inventories/hosts.yml \
  host-library-infra/ansible/playbooks/db2_data.yml

ansible-playbook -i host-library-infra/ansible/inventories/hosts.yml \
  host-library-infra/ansible/playbooks/compile_host.yml

ansible-playbook -i host-library-infra/ansible/inventories/hosts.yml \
  host-library-infra/ansible/playbooks/run_host.yml

ansible-playbook -i host-library-infra/ansible/inventories/hosts.yml \
  host-library-infra/ansible/playbooks/host_collect_artifacts.yml
```

Or combined with default runtime policy:

```bash
cd host-library-infra/ansible
ansible-playbook -i inventories/hosts.yml playbooks/smoke.yml

# explicit full smoke (includes run + artifact collection)
ansible-playbook -i inventories/hosts.yml playbooks/smoke-full.yml

# force runtime smoke regardless of default
ansible-playbook -i inventories/hosts.yml playbooks/smoke-full.yml \
  -e run_runtime_smoke=true

# force DB2 stages even if default skip is true
ansible-playbook -i inventories/hosts.yml playbooks/smoke-full.yml \
  -e run_runtime_skip_db2=false
```

## 6) Determinism and validation rules

1. Source upload must explicitly convert to `IBM-1047`.
2. SQL members must remain FB/80 compatible (`SCHEMA`, `TESTDATA`).
3. Each submitted job must be checked for return code.
4. Pipeline must fail on RC threshold breach.
5. No hardcoded secrets or personal credentials in repo.

## 7) Known gaps vs target host CI/CD

These items are not fully implemented yet:

1. Optional MQSC health checks exist as JCL assets, but are not wired into the
   Ansible smoke sequence.

## 8) Correlation rule (must not change)

MQ correlation strategy remains canonical and unchanged:

- Host/COBOL sets reply correlation by copying request MsgId to CorrelId.
- Java reads request JMSMessageID and selects reply by JMSCorrelationID.
- Correlation values are MQMD/JMS header concerns, not payload fields.

## 9) Related docs

- `docs/flows/flow-01/spec/FLOW-01_CICS_MQ_Manual_Then_CKTI.md`
- `docs/runbooks/HOST_SMOKE_AND_DEBUG.md`
- `docs/runbooks/MODULES_AND_MVN_COMMANDS.md`
- `host-library-infra/jcl/README_XPLORE_JOBS.md`
