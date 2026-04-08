# FLOW-02 — CI/CD Host Pipeline (Ansible + JCL on IBM Z Xplore)

Status: draft  
Last updated: 2026-04-08  
Scope: host-only pipeline (`host-library-infra`) for z/OS COBOL/MQ/DB2 delivery and smoke execution.

## 1) Purpose

This flow defines the canonical host delivery pipeline currently implemented in this repo:

1. Prepare datasets and upload host assets (COBOL/JCL/SQL) to z/OS.
2. Apply DB2 schema and test data.
3. Compile/link/bind host programs through JCL.
4. Optionally run host batch program for runtime smoke.

The flow is implemented with Ansible (`ibm.ibm_zos_core`) and JCL templates in
`host-library-infra/ansible`.

## 2) Current repo structure (as-is)

```text
host-library-infra/
  cobol/
    LIBMQTST.cbl
    LIBMQCIC.cbl
    LIBLOAN.cpy
  db2/
    schema.sql
    testdata.sql
  jcl/
    CBLMQDB2.jcl
    CBLMQCIC.jcl
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
      CBLMQCIC.jcl.j2
      LIBSCHEMA.jcl.j2
      LIBDATA.jcl.j2
      LIBMQTST.jcl.j2
      LIBMQTSTC.jcl.j2
      BINDPLAN.jcl.j2
    playbooks/
      library_deploy.yml
      db2_schema.yml
      db2_data.yml
      compile_host.yml
      run_host.yml
      smoke.yml
      library_tests.yml
```

Notes:
- Current GitHub Actions workflows in repo are `.github/workflows/ci.yml` and
  `.github/workflows/deploy.yml` (ECS deployment). There is no active
  `host-ci.yml` yet.
- Host inventory/group vars are under `host-library-infra/ansible/inventories`.

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

## 4) Canonical pipeline steps

### Step A — deploy datasets and sources

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
- Renders compile jobs locally (`CBLMQDB2`, `CBLMQCIC`) and uploads members.
- Uploads run/schema/data JCL template members.
- Uploads SQL members:
  - `{{ hlq }}.SQL(SCHEMA)`
  - `{{ hlq }}.SQL(TESTDATA)`

### Step B — DB2 schema

Playbook: `host-library-infra/ansible/playbooks/db2_schema.yml`

- Submits `{{ hlq }}.JCL(LIBSCHEM)`.
- Requires `RC == 0`.

### Step C — DB2 test data

Playbook: `host-library-infra/ansible/playbooks/db2_data.yml`

- Submits `{{ hlq }}.JCL(LIBDATA)`.
- Requires `RC == 0`.

### Step D — compile/link/bind host programs

Playbook: `host-library-infra/ansible/playbooks/compile_host.yml`

- Submits both compile members:
  - `{{ hlq }}.JCL(CBLMQDB2)` for `LIBMQTST`
  - `{{ hlq }}.JCL(CBLMQCIC)` for `LIBMQCIC`
- Current acceptance in playbook: `max_rc = 8`.

### Step E — optional run smoke

Playbook: `host-library-infra/ansible/playbooks/run_host.yml`

- Submits `{{ hlq }}.JCL(LIBMQTST)`.
- Requires `RC == 0`.

Important:
- `smoke.yml` currently imports deploy + db2 + compile only.
- `run_host.yml` is currently commented out in `smoke.yml` and must be run
  separately when runtime smoke is needed.

## 5) Standard commands

From repo root:

```bash
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
```

Or combined (without runtime step at the moment):

```bash
cd host-library-infra/ansible
ansible-playbook -i inventories/hosts.yml playbooks/smoke.yml
```

## 6) Determinism and validation rules

1. Source upload must explicitly convert to `IBM-1047`.
2. SQL members must remain FB/80 compatible (`SCHEMA`, `TESTDATA`).
3. Each submitted job must be checked for return code.
4. Pipeline must fail on RC threshold breach.
5. No hardcoded secrets or personal credentials in repo.

## 7) Known gaps vs target host CI/CD

These items are not fully implemented yet:

1. No dedicated `.github/workflows/host-ci.yml` that executes host Ansible flow.
2. No centralized artifact harvesting (spool/listings/load evidence) in repo as a
   dedicated `host_collect_artifacts` playbook.
3. Runtime smoke is not part of current `smoke.yml` import chain by default.
4. Optional MQSC health checks exist as JCL assets, but are not wired into the
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
