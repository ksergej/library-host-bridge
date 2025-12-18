# IBM Z Xplore JCL — Library Host Bridge

Purpose of jobs:
- `LIBSCHEMA.jcl` — create DB2 schema/tables for LIBRARY using DSNTEP2 and SQL from `host-library-infra/db2/schema.sql`.
- `LIBDATA.jcl` — load test data into the schema using DSNTEP2 and SQL from `host-library-infra/db2/testdata.sql`.
- `LIBMQTST.jcl` — run MQ/COBOL test program `LIBMQTST` (request/reply echo).

Placeholders / symbols:
- `&HLQ` — your HLQ on Xplore (e.g. `Z12345`).
- `&COBLOAD` — COBOL loadlib containing `LIBMQTST` (e.g. `&HLQ..LIB.LOAD`).
- `&MQLOAD` — IBM MQ loadlib (e.g. `CSQxxx.SCSQLOAD`).
- `&DB2LOAD` — DB2 SDSNLOAD (e.g. `SDSN.SDSNLOAD`).
- `&DB2SS` — DB2 subsystem (e.g. `DBC1`).
- `&DBRMLIB` — DBRM PDS/PDSE (e.g. `&HLQ..DBRM`).
- Replace these with actual dataset names in your Xplore environment. Credentials/DSNs must be provided manually (not stored in repo).

Run order (expected RC=0):
1) `LIBSCHEM` member (schema)
2) `LIBDATA.jcl`
3) `CBLMQDB2` member (compile + link-edit + DB2 bind for `LIBMQTST`)
4) `LIBMQRUN` member (runs `LIBMQTST`)

Notes:
- SQL sources reside under `host-library-infra/db2/` — copy/paste into SYSIN or upload to a dataset before running the JCL (Ansible playbooks place them into {{ hlq }}.SQL members).
- Ansible smoke pipeline (from repo root):
  - `cd host-library-infra/ansible && ansible-playbook -i inventories/hosts.yml playbooks/smoke.yml`
  Ensure vars (HLQ, DB2LOAD, MQLOAD, DB2SS, DBRMLIB, COBOL compiler/LE libs) are set in `inventories/group_vars/zos_xplore.yml`.
- MQ and DB2 LOADLIB names vary on Xplore; verify with the environment docs and update the placeholders.
- `LIBMQTST` now expects structured borrow payload (HOST-BORROW-REQUEST), checks DB2 LOAN for active loans, inserts a new loan when available, and returns HOST-BORROW-RESPONSE with `STATUS-CODE` (`OK`/`BUSY`/`ERR`) and `MESSAGE`.
- LIBMQTST now transforms MQ XML ↔ copybook internally (XML per `library-loan.xsd`; copybook in `LIBLOAN.cpy`), keeps CorrelId=MsgId in MQMD.
- LOAN_ID_NUM is a DB2 identity; COBOL derives external loan id as `L` + zero-padded number (CHAR(10)) and returns it in the reply (LOAN_ID not stored; see view V_LOAN for debugging). CorrelationId remains in MQMD (CorrelId = MsgId).
