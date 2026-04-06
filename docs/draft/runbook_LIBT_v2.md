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

---

## 7A) Make the load module available to CICS (LIBRARY / load path)

Symptom we hit:
- `LIBT` failed with:
  - `DFHAC2016 ... Transaction LIBT cannot run because program LIBMQCIC is not available.`
- `CEMT I PROG(LIBMQCIC)` showed `Leng(0000000000)` (length 0).

This indicates the PROGRAM resource exists, but CICS cannot locate/load the actual module.

### 7A.1 Check LIBRARY definition and DSN
We used:

- `CEMT I LIBRARY(Z88011LD)`

Observed:
- `Dsname01(Z88011.LOAD ...)`
- Status `Ena`

### 7A.2 Define LIBRARY (if not already present)
In CEDA:

`DEFine LIBrary(Z88011LD) GROup(Z88011)`

On the panel:
- `DSNAME01 ==> Z88011.LOAD`
- `Ranking ==> 50` (default ok)
- `Status ==> Enabled`

Press Enter to save.

### 7A.3 Install LIBRARY (common pitfalls)
CEDA requires GROUP or LIST:
- Use `INStall GROup(Z88011)`

If you see:
- `Install of LIBRARY Z88011LD failed because the installed definition is not disabled`
then the LIBRARY is already installed/enabled. Options:
- Disable/enable cycle (if authorized):
  - `CEMT SET LIBRARY(Z88011LD) DISABLED`
  - `CEMT SET LIBRARY(Z88011LD) ENABLED`
- Or use a new LIBRARY name (e.g., `Z88011L2`) if you cannot disable the existing one.

### 7A.4 Force CICS to reload the program (NEWCOPY) — this fixed Leng=0
Even with LIBRARY enabled, CICS may still have not loaded the module yet.

Command used:
- `CEMT SET PROG(LIBMQCIC) NEWCOPY`

After that, `CEMT I PROG(LIBMQCIC)` changed from:
- `Len(0000000000)`
to a non-zero length:
- `Len(0000038796)` (example)

Once the length is non-zero, `LIBT` can run the program.

### 7A.5 Quick diagnostic sequence
Use this exact checklist when you get DFHAC2016 / Leng=0:

1) `CEMT I TRANS(LIBT)`  (should show `Pro(LIBMQCIC)` and `Ena`)
2) `CEMT I PROG(LIBMQCIC)` (check `Len(...)`)
3) `CEMT I LIBRARY(Z88011LD)` (confirm DSN points to `Z88011.LOAD` and `Ena`)
4) `CEMT SET PROG(LIBMQCIC) NEWCOPY`
5) Re-check: `CEMT I PROG(LIBMQCIC)` (Len must be non-zero)
6) Run: `LIBT`



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


---


### 10.1 Next steps


Почему после stop/start CICS “пропадают” транзакции

Важно различать definition и install:
•	Definitions (TRANSACTION/PROGRAM/LIBRARY и т.д.) не пропадают, они лежат в DFHCSD (у тебя видно DSN=Z88011.CICS.DFHCSD на экране INSTALL).
•	Installed state (то, что реально “активно” в запущенном регионе) — пропадает при остановке региона, потому что это память работающего CICS.

После рестарта регион поднимает только то, что ему сказано установить автоматически:
•	через SIT/GRPLIST (группы, которые автo-install при старте),
•	или через PLTPI/PLT (ваши стартовые процедуры),
•	или через CPSM/BAS (если используется).

Поэтому у тебя и получается: после рестарта LIBT не доступна, пока ты не сделаешь CEDA INSTALL GROUP(Z88011).