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
- Replace these with actual dataset names in your Xplore environment. Credentials/DSNs must be provided manually (not stored in repo).

Run order (expected RC=0):
1) `LIBSCHEMA.jcl`
2) `LIBDATA.jcl`
3) `LIBMQTST.jcl` (verifies MQ path)

Notes:
- SQL sources reside under `host-library-infra/db2/` — copy/paste into SYSIN or upload to a dataset before running the JCL.
- MQ and DB2 LOADLIB names vary on Xplore; verify with the environment docs and update the placeholders.
- `LIBMQTST` now expects structured borrow payload (HOST-BORROW-REQUEST), checks DB2 LOAN for active loans, inserts a new loan when available, and returns HOST-BORROW-RESPONSE with `STATUS-CODE` (`OK`/`BUSY`/`ERR`) and `MESSAGE`.
