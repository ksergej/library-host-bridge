# Mini-runbook — CICS enablement for LIBMQCIC (MQ + DB2)

This runbook assumes you already have:
- Load module: `Z88011.LOAD(LIBMQCIC)`
- DBRM: `Z88011.DBRMLIB(LIBMQCIC)`
- DB2 bind succeeded via `BIND PLAN(Z88011) ...` (so package exists and plan includes it)
- CICS region is up (APPLID `CICSTS62`)

---

## 0) Pre-flight: access level

You’ll need one of these:
- **Full admin/dev access** (CEDA/CEMT) to define & install resources, OR
- A teammate/admin who can define resources for you

If `CEDA` or `CEMT` is “not authorized”, skip to **Section 6** (what to ask admin for).

---

## 1) Create CICS PROGRAM resource for LIBMQCIC

### Option A — via CEDA (typical)
1) In CICS, run: `CEDA`
2) `DEFINE PROGRAM(LIBMQCIC)`
3) Set (minimum):
- **PROGRAM**: `LIBMQCIC`
- **LANGUAGE**: `COBOL`
- **RESIDENT**: `NO` (default ok)
- **RELOAD**: `NO` (default ok)
- **CEDA GROUP**: choose your dev group (e.g., `Z88011`)

4) Ensure CICS can find the load module:
- Either the CICS region already has `Z88011.LOAD` in its **DFHRPL**
- Or admin must add it (see Section 6)

5) Install:
- `CEDA INSTALL PROGRAM(LIBMQCIC)`

### Quick verification
- `CEMT I PROGRAM(LIBMQCIC)` → should show `ENABLED` and `STATUS`

---

## 2) Create CICS TRANSACTION LIBT to start the program

### Recommended MVP transaction design
- Transaction ID: **LIBT**
- PROGRAM: **LIBMQCIC**
- No COMMAREA needed for MVP (program reads/writes via MQ)

### CEDA steps
1) `CEDA DEFINE TRANSACTION(LIBT)`
2) Set (minimum):
- **TRANSACTION**: `LIBT`
- **PROGRAM**: `LIBMQCIC`
- **PROFILE**: default ok
- **COMMAREA**: none required for MVP

3) Install:
- `CEDA INSTALL TRANSACTION(LIBT)`

### Quick verification
- `CEMT I TRANS(LIBT)` → should be `ENABLED`

---

## 3) Manual MVP test (Stage 1)

### Goal
- Put 1 request message to `LIB.REQ.Q`
- Manually run transaction `LIBT`
- Observe reply on `LIB.REP.Q` (CorrelationId = request MsgId)

### Steps
1) From Spring Boot, send request (as you do today).
2) In CICS, type: `LIBT`
3) Program should:
- MQGET one message (NO-WAIT)
- Execute DB2 logic
- MQPUT reply + SYNCPOINT

### What to observe
- In CICS logs / console output: your `DISPLAY` lines from program
- In MQ: reply message appears with **CorrelId = request MsgId**

---

## 4) Verify DB2 attach is active in CICS

Depending on site configuration, you can check DB2 resources with CEMT inquiries.

Try (one by one):
- `CEMT I DB2CONN`
- `CEMT I DB2ENTRY`
- `CEMT I DB2TRAN`

Expected:
- DB2 connection **OPEN/CONNECTED**
- Entries/transactions **ENABLED**
- Plan-related attributes visible (see Section 5)

If these commands are not recognized or not authorized, ask admin (Section 6).

---

## 5) Diagnose DB2 SQLCODEs (-805 / -811)

### A) SQLCODE -805 (package not found / plan mismatch)
**Meaning**
- The package exists, but the **PLAN used by the CICS-DB2 thread does not include your package**, OR
- The package was bound into a different collection than what runtime expects

**Fast checks**
1) Confirm the package exists in catalog (`SYSIBM.SYSPACKAGE`) for `NAME='LIBMQCIC'`.
2) Determine which plan CICS uses:
   - Inspect `DB2ENTRY` / `DB2TRAN` (often contain PLAN)
   - Or `DB2CONN` defaults (depends on configuration)

**Fix**
- Configure the CICS DB2ENTRY/DB2TRAN to use `PLAN(Z88011)`, OR
- Rebind into the plan/collection that the region actually uses

### B) SQLCODE -811 (more than one row returned)
**Meaning**
- A `SELECT ... INTO` returned multiple rows.

**Fix**
- Add predicates so exactly one row matches, OR
- Use a cursor if multiple rows are valid.

---

## 6) If you need admin help — exact ask

### CICS resources
Please create/install in region `CICSTS62`:
- `PROGRAM(LIBMQCIC)` pointing to load module `LIBMQCIC`
- `TRANSACTION(LIBT)` running program `LIBMQCIC`

Ensure the region can load it:
- Add `Z88011.LOAD` to DFHRPL **or** copy member `LIBMQCIC` into an existing DFHRPL library.

### DB2 attach / plan
- Confirm DB2 attachment is active for the region
- Confirm which DB2 plan is used for user transactions
- Ensure that plan includes package `...LIBMQCIC...` OR allow plan `Z88011`

### MQ
- Ensure CICS region has MQ connection configured and that `LIB.REQ.Q` and `LIB.REP.Q` are accessible

---

## 7) Next (after manual MVP works)
- Enable MQ triggering on `LIB.REQ.Q`
- Configure initiation queue + PROCESS object
- Start CKTI to auto-start `LIBT` when messages arrive
