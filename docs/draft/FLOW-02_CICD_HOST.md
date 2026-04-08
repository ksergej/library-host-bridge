# FLOW-02_CICD_HOST.md

> Canonical spec moved to: `docs/flows/flow-02/spec/FLOW-02_CICD_HOST.md`

Library System — CI/CD for Host (z/OS + MQ + COBOL + DB2) via GitHub Actions

**Status:** Draft (ready for TODO breakdown)  
**Scope:** Host-only CI/CD (no ECS/Java runtime deployment)  
**Primary Goal:** Deterministic host pipeline from GitHub Actions:

1. Upload COBOL/copybooks/JCL to z/OS  
2. Compile + link via JCL  
3. Bind DB2 (PLAN/PACKAGE)  
4. Smoke checks (MQ/DB2/RC/Spool)  
5. Collect artifacts (spool, listings, load members)

---

## 0) Context and Constraints

This FLOW automates the **host** part of the system using:

- **GitHub Actions** as CI/CD runner
- **Ansible + ibm.ibm_zos_core** for z/OS operations
- **JCL** for compile/link/run
- **DB2 BIND** via DSN/IKJEFT01 JCL
- Optional **MQSC checks** via CSQUTIL COMMAND JCL

Constraints:

- No commercial Wazi Deploy.
- Must be deterministic and fail-fast (RC validation).
- Encoding is critical: sources must arrive in **IBM-1047**.
- Artifacts must always be available (even on failure).

---

## 1) Repository Layout (target)

All host automation is contained under `host-library-infra/`.

```text
host-library-infra/
  cobol/
    LIBMQTST.cbl
    LIBLOAN.cpy
    ... (other *.cbl/*.cpy)
  jcl/
    LIBMQTSTC.jcl               # compile/link (COBOL + MQ + DB2 precompile)
    LIBMQTST_BIND.jcl           # DB2 bind plan/package
    LIBMQTST_SMOKE.jcl          # smoke run (exec program + simple checks)
    MQSC_CHECK.jcl              # optional: CSQUTIL COMMAND MQSC checks
  db2/
    schema.sql
    testdata.sql
  ansible/
    ansible.cfg
    inventories/
      xplore.ini
    group_vars/
      all.yml
    playbooks/
      host_deploy.yml
      host_compile.yml
      host_bind_db2.yml
      host_smoke.yml
      host_collect_artifacts.yml

.github/
  workflows/
    host-ci.yml
```

---

## 2) Inputs

### 2.1 GitHub Secrets (required)

Configure in GitHub → **Settings → Secrets and variables → Actions**:

- `ZOS_HOST` (e.g. `204.90.115.200`)
- `ZOS_SSH_USER` (e.g. `Z88011`)
- `ZOS_SSH_PRIVATE_KEY` (private key PEM)
- `ZOS_SSH_PORT` (optional; default `22`)
- `ZOS_HLQ` (e.g. `Z88011`)

DB2:

- `DB2_SUBSYSTEM` (e.g. `DBDG`)
- `DB2_PLAN` (e.g. `Z88011`)
- `DB2_COLLID` (e.g. `DSN_DEFAULT_COLLID_Z88011`)

Optional for MQSC checks:

- `MQ_QMGR` (e.g. `CSQ9`)

### 2.2 Repo-controlled defaults (group_vars)

File: `host-library-infra/ansible/group_vars/all.yml`

```yaml
PYZ: "/usr/lpp/IBM/cyp/v3r9/pyz"
ZOAU: "/usr/lpp/IBM/zoautil"
ansible_python_interpreter: "{{ PYZ }}/bin/python3"

HLQ: "{{ lookup('env', 'ZOS_HLQ') | default('Z00000', true) }}"
COBSRC: "{{ HLQ }}.COBOL"
COPYLIB: "{{ HLQ }}.COPY"
JCLLIB: "{{ HLQ }}.JCL"
LOADLIB: "{{ HLQ }}.LOAD"
DBRMLIB: "{{ HLQ }}.DBRM"

DB2LOAD: "SDSN.SDSNLOAD"
MQLOAD: "CSQ900.SCSQLOAD"
COBOL_COMPILER_LOADLIB: "YOUR.COBOL.COMPILER.LOADLIB"

DB2_SUBSYSTEM: "{{ lookup('env', 'DB2_SUBSYSTEM') | default('DBDG', true) }}"
DB2_PLAN: "{{ lookup('env', 'DB2_PLAN') | default(HLQ, true) }}"
DB2_COLLID: "{{ lookup('env', 'DB2_COLLID') | default('DSN_DEFAULT_COLLID_' + HLQ, true) }}"
```

---

## 3) Outputs (Artifacts)

Artifacts uploaded by GitHub Actions:

1. **JES spool** for each submitted job  
   `host-library-infra/ansible/artifacts/spool/<jobname>.txt`
2. **Compiler listings** (optional)  
   `host-library-infra/ansible/artifacts/listings/*`
3. **Load members evidence**  
   `host-library-infra/ansible/artifacts/load_members.txt`
4. Optional MQSC output  
   `host-library-infra/ansible/artifacts/mqsc_check.txt`

**Rule:** artifacts must be present for both PASS and FAIL runs.

---

## 4) Flow Steps (deterministic pipeline)

### 4.1 Step A — Deploy sources to z/OS (upload)

Playbook: `host-library-infra/ansible/playbooks/host_deploy.yml`

Responsibilities:

1. Ensure datasets exist (`zos_data_set`):
   - `&HLQ..COBOL`
   - `&HLQ..COPY`
   - `&HLQ..JCL`
   - `&HLQ..DBRM`
   - `&HLQ..LOAD` (PDSE recommended)
2. Upload members (`zos_copy`) with encoding conversion:
   - `host-library-infra/cobol/*.cbl` → `&COBSRC(...)`
   - `host-library-infra/cobol/*.cpy` → `&COPYLIB(...)`
   - `host-library-infra/jcl/*.jcl`   → `&JCLLIB(...)`

Example snippet:

```yaml
- name: Copy COBOL sources (EBCDIC)
  ibm.ibm_zos_core.zos_copy:
    src: "{{ playbook_dir }}/../../cobol/LIBMQTST.cbl"
    dest: "{{ COBSRC }}(LIBMQTST)"
    encoding:
      from: ISO8859-1
      to: IBM-1047
```

---

### 4.2 Step B — Compile + link via JCL

Playbook: `host-library-infra/ansible/playbooks/host_compile.yml`

Submit compile job: `JCLLIB(LIBMQTSTC)`

Requirements:

- Use `zos_job_submit` with `location: DATA_SET`
- Wait for completion and fetch output with `zos_job_output`
- Fail workflow if RC != 0

Example (concept):

```yaml
- name: Submit compile job
  ibm.ibm_zos_core.zos_job_submit:
    src: "{{ JCLLIB }}(LIBMQTSTC)"
    location: DATA_SET
    wait: true
  register: compile_job

- name: Fetch spool
  ibm.ibm_zos_core.zos_job_output:
    job_id: "{{ compile_job.job_id }}"
    save_to: "{{ playbook_dir }}/../artifacts/spool/LIBMQTSTC.txt"
```

---

### 4.3 Step C — DB2 BIND (PLAN/PACKAGE)

Playbook: `host-library-infra/ansible/playbooks/host_bind_db2.yml`

Submit bind job: `JCLLIB(LIBMQTST_BIND)`

Minimal JCL skeleton (template to be stored in repo as `host-library-infra/jcl/LIBMQTST_BIND.jcl`):

```jcl
//BINDJOB  JOB CLASS=A,MSGCLASS=X,NOTIFY=&SYSUID
//BIND     EXEC PGM=IKJEFT01,REGION=0M
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
  DSN SYSTEM(&DB2SUB)
  BIND PLAN(&PLAN) PKLIST(&COLLID.*) ACTION(REPLACE)
       VALIDATE(RUN) ISOLATION(CS) ENCODING(EBCDIC)
  END
/*
```

Ansible must replace:
- `&DB2SUB` ← `DB2_SUBSYSTEM`
- `&PLAN`   ← `DB2_PLAN`
- `&COLLID` ← `DB2_COLLID`

Fail conditions:
- non-zero RC
- DSNT/DSN messages indicating bind failure

---

### 4.4 Step D — Smoke run (Host runtime verification)

Playbook: `host-library-infra/ansible/playbooks/host_smoke.yml`

Submit: `JCLLIB(LIBMQTST_SMOKE)`

Smoke job should:
- run program from `&LOADLIB`
- execute minimal MQ + DB2 path
- emit canonical success marker in spool, e.g.:
  - `PROCESS COMPLETE, STATUS=OK`
  - or `SQLSTATE=00000`

Playbook validations:
1) RC == 0
2) Spool contains success marker(s)

---

### 4.5 Step E — Collect artifacts (always)

Playbook: `host-library-infra/ansible/playbooks/host_collect_artifacts.yml`

Responsibilities:
- Ensure `artifacts/` exists
- Copy in:
  - spool files for compile/bind/smoke
  - load member listing (see below)
  - optional listing files

Load members evidence (example):
- use `zos_mvs_raw` or `zos_tso_command`/`zoau` to list PDS members (implementation choice)
- store as `artifacts/load_members.txt`

---

## 5) Optional Step — MQSC checks via CSQUTIL COMMAND

File: `host-library-infra/jcl/MQSC_CHECK.jcl`

Purpose:
- verify queue depths
- verify channel existence

Commands example:

```text
DISPLAY QLOCAL(Z88011.MQZ3.QLOCAL) CURDEPTH
DISPLAY QLOCAL(Z88011.MQZ3.REPLYTO.QLOCAL) CURDEPTH
DISPLAY CHANNEL(WAS.JMS.SVRCONN) CHLTYPE TRPTYPE
DISPLAY QMGR
```

This step is optional in P0, but helpful for debugging.

---

## 6) GitHub Actions Workflow (minimal)

File: `.github/workflows/host-ci.yml`

```yaml
name: host-ci

on:
  workflow_dispatch:
  push:
    branches: [ "main" ]
  pull_request:

jobs:
  host:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.11"

      - name: Install Ansible + collection
        run: |
          python -m pip install --upgrade pip
          pip install "ansible-core==2.17.*"
          ansible-galaxy collection install ibm.ibm_zos_core

      - name: Configure SSH
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.ZOS_SSH_PRIVATE_KEY }}" > ~/.ssh/id_rsa
          chmod 600 ~/.ssh/id_rsa
          ssh-keyscan -p "${{ secrets.ZOS_SSH_PORT || 22 }}" "${{ secrets.ZOS_HOST }}" >> ~/.ssh/known_hosts

      - name: Run host pipeline (deploy → compile → bind → smoke)
        env:
          ZOS_HLQ: ${{ secrets.ZOS_HLQ }}
          DB2_SUBSYSTEM: ${{ secrets.DB2_SUBSYSTEM }}
          DB2_PLAN: ${{ secrets.DB2_PLAN }}
          DB2_COLLID: ${{ secrets.DB2_COLLID }}
        run: |
          cd host-library-infra/ansible
          ansible-playbook -i inventories/xplore.ini playbooks/host_deploy.yml
          ansible-playbook -i inventories/xplore.ini playbooks/host_compile.yml
          ansible-playbook -i inventories/xplore.ini playbooks/host_bind_db2.yml
          ansible-playbook -i inventories/xplore.ini playbooks/host_smoke.yml
          ansible-playbook -i inventories/xplore.ini playbooks/host_collect_artifacts.yml

      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: host-artifacts
          path: host-library-infra/ansible/artifacts/
```

Inventory requirements:
- `inventories/xplore.ini` must reference `${{ secrets.ZOS_HOST }}` and `${{ secrets.ZOS_SSH_USER }}` via env or templated file.
- No credentials hard-coded in repo.

---

## 7) Determinism Rules (MUST)

1. All dataset names derive from `ZOS_HLQ`.
2. Encoding conversion is explicit on upload (to IBM-1047).
3. Every `zos_job_submit` has spool captured and stored.
4. Any non-zero RC fails pipeline.
5. Smoke requires both RC==0 and success marker in spool.
6. Artifacts are uploaded even on failure.

---

## 8) Acceptance Criteria (P0)

✅ PR triggers workflow; on fail, artifacts are still uploaded.  
✅ On main, the workflow can deterministically:
- upload sources
- compile/link (RC=0)
- bind DB2 (RC=0)
- run smoke (RC=0 and marker found)
- upload spool + load member listing

---

## 9) TODO Breakdown (next)

1. Implement playbooks:
   - `host_deploy.yml`
   - `host_compile.yml`
   - `host_bind_db2.yml`
   - `host_smoke.yml`
   - `host_collect_artifacts.yml`
2. Finalize JCL:
   - `LIBMQTSTC.jcl`
   - `LIBMQTST_BIND.jcl`
   - `LIBMQTST_SMOKE.jcl`
   - `MQSC_CHECK.jcl` (optional)
3. Implement artifact capture:
   - spool saving paths standardized
   - load member listing to `artifacts/load_members.txt`
4. Inventory and secret wiring:
   - `xplore.ini` uses env vars, no hardcoded host/user
5. Smoke markers:
   - define canonical strings to match in spool

