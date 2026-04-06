# runbook_LIBT.md — Installing and validating CICS transaction LIBT → program LIBMQCIC

Context:
- CICS region APPLID: `CXZ88011` (SYSID `S750`)
- CSD dataset: `Z88011.CICS.DFHCSD`
- Goal: define and install:
  - `PROGRAM(LIBMQCIC)`
  - `TRANSACTION(LIBT)` that runs `PROGRAM(LIBMQCIC)`
- Verification via `CEMT`

This runbook documents exactly what we did and what we checked, step-by-step.

---

## 1) Preconditions

1. You can log on to the CICS region and run:
   - `CEMT` (for runtime inquiries)
   - `CEDA` (for resource definition and install)

2. The load module `LIBMQCIC` is already built and available in a loadlib that the region can reach (DFHRPL), or it can be added later.

---

## 2) Enter CEDA

From a “clean” CICS command line:
- Type: `CEDA` and press Enter.

You should see the CEDA command menu (ADD/ALTER/DEFINE/INSTALL/DISPLAY…).

---

## 3) DEFINE PROGRAM(LIBMQCIC)

On the CEDA command line, entered:

`DEFine PROGram(LIBMQCIC) GROup(Z88011)`

CEDA responded that the group was new:
- `I New group Z88011 created.`

On the PROGRAM definition panel, we set/confirmed:

- `PROGram` = `LIBMQCIC`
- `Group` = `Z88011`
- `Language` = `Cobol`  **(must be set; was initially blank)**
- `Status` = `Enabled`
- `EXECKey` = `User`
- `Concurrency` = `Quasirent` (default; acceptable for MVP)

Action:
- Press Enter to save the definition into CSD.

---

## 4) INSTALL the group (PROGRAM)

First attempt:
- `INStall PROGram(LIBMQCIC)`

CEDA redirected to the generic INSTALL panel and displayed:
- `GROUP or LIST must be specified.`

Correct action used:
- `INStall GROup(Z88011)`

Result:
- `INSTALL SUCCESSFUL`

This installs all resources currently defined in group `Z88011` (at that point: the PROGRAM).

---

## 5) DEFINE TRANSACTION(LIBT) (already existed)

We verified if the transaction exists in the CSD:

`DIsplay TRANsaction(LIBT)`

Result list showed:

- `LIBT     TRANSACTION  Z88011  <timestamp>`

This means `TRANSACTION(LIBT)` already existed and belonged to group `Z88011`.

(If it had not existed, the intended creation command would have been:
`DEFine TRANsaction(LIBT) PROGram(LIBMQCIC) GROup(Z88011)` and then save.)

---

## 6) INSTALL the group (TRANSACTION)

To ensure the transaction is installed in the running region:

- `INStall GROup(Z88011)`

Result:
- `INSTALL SUCCESSFUL`

(Installing the group multiple times is fine; CICS will install/refresh the resources as needed.)

---

## 7) Verify runtime status via CEMT

### 7.1 Verify TRANSACTION LIBT
In CICS command line, ran:

`CEMT I TRANS(LIBT)`

Observed output:

- `Tra(LIBT) ... Pro(LIBMQCIC) ... Ena`
- `RESPONSE: NORMAL`

Key validations:
- Transaction exists and is **Enabled**
- It points to **Program LIBMQCIC**
- CICS accepted the inquiry (`RESPONSE: NORMAL`)

### 7.2 (Optional) Verify PROGRAM LIBMQCIC
Recommended check:

`CEMT I PROG(LIBMQCIC)`

Expected:
- Program is present and enabled.
- If “NOT FOUND” or load errors appear at run time, it usually means DFHRPL does not include the load library containing `LIBMQCIC`.

---

## 8) Manual run test (Stage 1 MVP)

From a clean CICS command line:
- Type: `LIBT`

Expected behaviors:
- If the request MQ queue is empty: program may end quickly (NO-WAIT MQGET).
- If a message exists on request queue: program should process one message and put a reply.

If you see an error:
- “Program not found / cannot load” → DFHRPL/loadlib issue.
- MQ errors (`MQCONN/MQOPEN` RC != 0) → MQ connectivity/authorization/queue names.
- DB2 `-805` → plan/package mismatch for the CICS-DB2 thread.

---

## 9) Troubleshooting checklist

### A) Program load failures
Symptoms:
- DFH… messages about not finding or not loading `LIBMQCIC`.

Fix:
- Ensure `LIBMQCIC` is in a library in DFHRPL (admin task) or copy it into an existing DFHRPL library.

### B) DB2 -805 at runtime
Meaning:
- The CICS DB2 thread is using a PLAN that does not include your package.

Fix:
- Determine the plan used by the region/DB2ENTRY and include your package (or configure to use your plan `Z88011`).

### C) MQ unresolved or RC failures
Meaning:
- Link-edit didn’t include MQ CICS stub or runtime MQ is not available to CICS.

Fix:
- Ensure link included `CSQCSTUB`.
- Verify MQ connection definitions/authorization in region.

---

## 10) Summary of what we validated

- `CEDA` available and usable.
- `PROGRAM(LIBMQCIC)` defined in group `Z88011`, with `Language=Cobol`.
- Group installation succeeded (`INSTALL SUCCESSFUL`).
- Transaction `LIBT` exists in CSD and is installed.
- `CEMT I TRANS(LIBT)` shows `Pro(LIBMQCIC)` and `Ena`, response normal.
