# runbook_db2_cics.md
DB2 z/OS + CICS + COBOL: how to do **BIND PLAN** (and packages) correctly
> Scope: classic CICS-DB2 (RDO resources DB2CONN/DB2ENTRY/DB2TRAN), COBOL with embedded SQL, static SQL (DBRM → package → plan).

---

## 0) The mental model (what you’re binding)
1. **COBOL+SQL source** → DB2 precompile (or SQL coprocessor) produces:
   - **DBRM** (Database Request Module)
   - modified COBOL source (SQL calls stubbed)
2. **DBRM** → **BIND PACKAGE** (recommended) produces:
   - **PACKAGE** in a **COLLECTION**
3. One or more packages → **BIND PLAN** produces:
   - **PLAN**, referencing packages via **PKLIST**
4. In CICS:
   - **DB2CONN** points to a **PLAN** for the region (or uses dynamic plan selection via DB2ENTRY/DB2TRAN mapping depending on setup)
   - **DB2ENTRY/DB2TRAN** control thread usage and which transactions are allowed/associated

**Best practice today:** bind packages, then bind a plan that points to packages. (Avoid DBRM-in-plan directly unless you’re stuck with legacy.)

---

## 1) Decide your naming conventions (do this once)
Typical and workable scheme:

- **DBRM member** = program name (e.g. `LIBMQCIC`)
- **PACKAGE** name = same as DBRM member (`LIBMQCIC`)
- **COLLECTION** = environment / region / team (e.g. `Z88011COLL`, `DEVZ88011`, etc.)
- **PLAN** = region plan or application plan (e.g. `CXZ88011P` or `LIBPLAN`)

Two common patterns:

### Pattern A — “One plan per CICS region” (simple & common)
- PLAN `CXZ88011P`
- PKLIST contains `COLLECTION.*` for that region
- Any new program just adds a package in that collection; plan rarely changes

### Pattern B — “Plan per application” (stricter, more controlled)
- PLAN `LIBPLAN`
- PKLIST includes only the packages for that application
- More change control, but more plan maintenance

If you’re iterating fast in a personal region, **Pattern A** is easiest.

---

## 2) Build outputs you must have
From your build pipeline (JCL or tooling) you need:

- `DBRM` dataset/member (usually PDS/E)
- load module in DFHRPL (program load library)
- optional: DB2 “consistency token” is handled automatically, but mismatches cause -818

### SQL processing options (compiler / precompile)
- If you use **DB2 SQL coprocessor** with Enterprise COBOL:
  - compile with `CBL ... SQL(...)` and ensure `DSNHDECP` is available
- If you use classic precompile:
  - run `DSNHPC` → compile → link-edit

Either is fine as long as you consistently produce the DBRM and bind it.

---

## 3) JCL: BIND PACKAGE (recommended)
Run BIND under TSO batch using `IKJEFT01` (or `DSNTEP2` if your shop prefers).

### Example (IKJEFT01 + DSN)
```jcl
//BINDPKG  EXEC PGM=IKJEFT01,REGION=0M
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
  DSN SYSTEM(DSND)            /* <-- DB2 subsystem */
  BIND PACKAGE(Z88011COLL)    /* <-- collection */
       MEMBER(LIBMQCIC)       /* <-- DBRM member name */
       OWNER(Z88011)          /* <-- package owner */
       QUALIFIER(LIBSCH)      /* <-- default schema if you rely on it */
       ACTION(REPLACE)
       VALIDATE(BIND)
       ISOLATION(CS)
       RELEASE(COMMIT)        /* or DEALLOCATE; COMMIT is typical */
       CURRENTDATA(NO)
       DEGREE(1)
  END
/*
//DBRMLIB  DD DISP=SHR,DSN=Z88011.DBRMLIB
```

Notes:
- `MEMBER()` must match the DBRM member name.
- `QUALIFIER()` is optional; only use if you understand the effect (implicit schema).
- `RELEASE(COMMIT)` is the common choice; `DEALLOCATE` keeps resources longer (sometimes used for performance, but be cautious).

---

## 4) JCL: BIND PLAN (to packages)
### Example plan referencing the whole collection
```jcl
//BINDPLAN EXEC PGM=IKJEFT01,REGION=0M
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
  DSN SYSTEM(DSND)
  BIND PLAN(CXZ88011P)
       OWNER(Z88011)
       QUALIFIER(LIBSCH)
       ACTION(REPLACE)
       VALIDATE(BIND)
       ISOLATION(CS)
       RELEASE(COMMIT)
       ACQUIRE(USE)
       PKLIST(Z88011COLL.*)   /* <-- key line */
  END
/* 
```

If you want a tighter PKLIST:
```text
PKLIST(Z88011COLL.LIBMQCIC, Z88011COLL.OTHERPGM)
```

### When to rebind the plan?
- Pattern A (plan per region): **rarely**—only if you change PKLIST policy or move collections.
- Pattern B (plan per app): whenever you add/remove packages from that plan.

---

## 5) Grants / auth (avoid -551 / authorization failures)
You typically need:
- `GRANT EXECUTE ON PLAN <plan> TO <authid>`
- `GRANT EXECUTE ON PACKAGE <coll>.<pkg> TO <authid>`

**Who is `<authid>`?**
- Often the **CICS region userid** (the userid that runs the DFHSIP address space)
- Or a RACF group used for the region
- Sometimes transaction userids if you use SIGNON and transaction-level auth

If you don’t know, start with granting to the region userid and tighten later.

---

## 6) CICS side: wire DB2 to a COBOL/CICS transaction (no RCT era)

### Concepts (modern CICS/DB2 integration)
- **DB2CONN** = region-level connection to a DB2 subsystem (DB2ID) + default plan/auth settings.
- **DB2ENTRY** = “thread pool” / routing bucket: thread limits, protectnum, default plan/authid for a set of transactions.
- **DB2TRAN** = mapping rule: **TRANID → DB2ENTRY** (and optionally auth behavior, depending on site standards).

> Key point: **BIND (PACKAGE/PLAN)** is DB2 catalog state (persists across CICS restarts).  
> **DB2CONN/DB2ENTRY/DB2TRAN** are CICS RDO definitions in **DFHCSD** (must be *installed* into the region each start).

### Minimum checklist
1) **DB2CONN is installed + enabled**
- DB2ID points to your subsystem (example: `DBDG`)
- PLAN points to a plan that contains your application packages (or a “router” plan)
- Check with: `CEMT I DB2CONN` (or `CEMT I DB2CONN` / `CEMT SET DB2CONN OPEN` depending on your shop)

2) **DB2ENTRY exists**
- Defines thread usage: `THREADLIMIT`, `TYPETERM`, `PROTECTNUM`, etc.
- Usually also defines which **PLAN** to use (either here or in DB2CONN)

3) **DB2TRAN exists for each transaction that uses DB2**
- Example: transaction `LIBT` should be linked to a DB2ENTRY used by your app.

### Concrete example for your case (LIBT → LIBMQCIC)
Assume:
- DB2 subsystem: `DBDG`
- Collection: `Z88011COLL`
- Package member: `LIBMQCIC`
- Plan: `Z88011` (your plan name)

#### A) DB2 objects (BIND) – recommended “clean” pattern
Do **two separate binds**: one for the **PACKAGE**, one for the **PLAN**.

**Bind the package (from DBRMLIB member):**
```
//BINDPKG  EXEC PGM=IKJEFT01
//STEPLIB  DD  DSN=DSND10.DBDG.SDSNEXIT,DISP=SHR
//         DD  DSN=DSND10.SDSNLOAD,DISP=SHR
//DBRMLIB  DD  DSN=Z88011.DBRMLIB,DISP=SHR
//SYSTSPRT DD  SYSOUT=*
//SYSPRINT DD  SYSOUT=*
//SYSTSIN  DD  *
  DSN SYSTEM(DBDG)
  BIND PACKAGE(Z88011COLL) MEMBER(LIBMQCIC)
       ACTION(REPLACE) ISOLATION(CS) ENCODING(EBCDIC)
  END
/*
```

**Bind (or rebind) the plan to include your collection:**
```
//BINDPLAN EXEC PGM=IKJEFT01
//STEPLIB  DD  DSN=DSND10.DBDG.SDSNEXIT,DISP=SHR
//         DD  DSN=DSND10.SDSNLOAD,DISP=SHR
//SYSTSPRT DD  SYSOUT=*
//SYSPRINT DD  SYSOUT=*
//SYSTSIN  DD  *
  DSN SYSTEM(DBDG)
  BIND PLAN(Z88011)
       PKLIST(Z88011COLL.*)
       ACTION(REPLACE) ISOLATION(CS) ENCODING(EBCDIC)
  END
/*
```

**About your DSNT241I warning**
You saw:
- `DSNT241I ... AUTHORIZATION-ID Z88011 NOT AUTHORIZED TO EXECUTE PACKAGE Z88011COLL.*`

This means the **BIND authid** (or plan owner/authid) lacks **EXECUTE** on one or more packages in the PKLIST.  
Fix options (choose what matches your security model):
- Ensure packages in `Z88011COLL` are **owned by / executable by** the plan owner (or the runtime authid).
- `GRANT EXECUTE ON PACKAGE Z88011COLL.<pkg> TO <authid-or-role>;`
- Or bind the plan with an authid that is authorized and set proper OWNER/QUALIFIER per standards.

#### B) CICS resources (RDO): DB2CONN / DB2ENTRY / DB2TRAN
**Option 1 (simple): use DB2CONN default plan + map transactions to an entry**
- DB2CONN: `DB2ID(DBDG) PLAN(Z88011)`
- DB2ENTRY: define thread behavior (can also specify PLAN if your shop uses per-entry plans)
- DB2TRAN: `TRANSID(LIBT) ENTRY(<entryname>)`

**CEDA (interactive) – sketch**
- `CEDA DEFINE DB2CONN(<name>) DB2ID(DBDG) PLAN(Z88011) ...`
- `CEDA DEFINE DB2ENTRY(<entryname>) PLAN(Z88011) THREADLIMIT(n) PROTECTNUM(m) ...`
- `CEDA DEFINE DB2TRAN(LIBT) ENTRY(<entryname>)`

**DFHCSDUP (batch “IaC” style) – sketch**
```
DEFINE DB2CONN(CXZDB2) GROUP(Z88011) DB2ID(DBDG) PLAN(Z88011) ...
DEFINE DB2ENTRY(LIBENT) GROUP(Z88011) PLAN(Z88011) THREADLIMIT(10) PROTECTNUM(2) ...
DEFINE DB2TRAN(LIBT)    GROUP(Z88011) ENTRY(LIBENT) ...
INSTALL  DB2CONN(CXZDB2)
INSTALL  DB2ENTRY(LIBENT)
INSTALL  DB2TRAN(LIBT)
```

> Exact attribute names vary a bit by CICS TS level and shop defaults (AUTHID, AUTHTYPE, THREADWAIT, ACCOUNTREC, etc.).
> Use `CEDA VIEW` on an existing working DB2CONN/ENTRY/TRAN in your region as a “golden template”, then copy the same attributes.

### Make resources survive a CICS restart (stop “disappearing transactions”)
What happened to you is consistent with a “personal region” startup that:
- recreates/starts from a fresh DFHCSD, **or**
- starts with your DFHCSD but **does not auto-install** your application group.

Best practice options:

1) **Add your group to GRPLIST in the SIT (recommended)**
- In your SYSIN SIT overrides (in the startup JCL), add something like:
  - `GRPLIST=(DFH$... ,Z88011)`  (include existing groups + your group)
- Then CICS will install that group automatically at startup.

2) **Use PLTPI to install groups at startup**
- If your shop uses PLTPI programs, you can run install commands early in startup.
- This is less common for simple personal regions but works in controlled setups.

3) **As a fallback**: run `CEDA INSTALL GROUP(Z88011)` manually (what you did)

---

## 7) Troubleshooting quick map
### SQLCODE -805 (package not found)
- Package not bound, wrong collection, or plan PKLIST doesn’t include it.
- Fix: bind package into correct collection; verify plan PKLIST includes it; rebind plan if needed.

### SQLCODE -818 (timestamp / consistency token mismatch)
- Program load module doesn’t match DBRM/package you bound.
- Fix: rebuild (precompile/compile/link) and rebind package; ensure the DFHRPL load module is the new one.

### SQLCODE -551 (not authorized)
- Missing EXECUTE on plan/package or missing table privileges.
- Fix: GRANT EXECUTE; GRANT table privileges; check which authid CICS uses.

### SQLCODE -904 / -911 / -913
- Resource unavailable / deadlock / timeout.
- Fix: check locking, isolation, commit frequency, and resource status.

---

## 8) Verification checklist
### In DB2 (via DSN session)
- Verify plan exists: `-DISPLAY PLAN(CXZ88011P)`
- Verify package exists: `-DISPLAY PACKAGE(Z88011COLL) MEMBER(LIBMQCIC)` (or your shop’s tooling)

### In CICS
- Confirm program installed/enabled: `CEMT INQUIRE PROGRAM(LIBMQCIC)`
- Confirm transaction points to program: `CEMT INQUIRE TRANSACTION(LIBT)`
- Confirm DB2 resources installed/enabled (names vary by shop): `CEMT INQUIRE DB2CONN` etc.

---

## 9) Recommended “dev loop” (fast + correct)
1. Edit COBOL
2. Build: SQL preprocess → compile → link-edit → put load module in DFHRPL library
3. Bind package (ACTION REPLACE) into your dev collection
4. (Only if needed) bind plan or ensure PKLIST already covers the collection
5. In CICS: NEWCOPY or DISABLE/ENABLE program; run transaction; check messages

---

## 10) Minimal decisions you should capture in your project
- DB2 subsystem (`DSN SYSTEM(...)`)
- Collection naming policy
- Plan naming policy
- Plan strategy (one plan per region vs per app)
- Grant policy (region userid vs groups)
- RELEASE/ISOLATION defaults

## Troubleshooting: `DSNT235I ... PRIVILEGE = BINDADD` when `BIND PACKAGE`

### What it means
`BIND PACKAGE(collection) MEMBER(...)` **creates or replaces a package** in the target **collection**.  
In DB2 for z/OS, creating a package requires the **BINDADD** privilege (or higher authorities such as **SYSADM/DBADM**), depending on site security rules.

Your output shows:

- `DSNT235I ... USING Z88011 AUTHORITY ... PRIVILEGE = BINDADD`
- `UNSUCCESSFUL BIND FOR PACKAGE = ZXPDB2.Z88011COLL.LIBMQCIC`

So the binder authid `Z88011` simply **is not allowed to create/replace packages** in that collection/database.

### The “correct” pattern (practical and common)
Use **two IDs**:
1) **Build/BIND ID** (has BINDADD / DBADM etc.) → used only in build pipeline or batch job to bind packages and plan.  
2) **Runtime ID** (the CICS user/region/transaction user) → used to *execute* the plan/packages at runtime.

#### A) Bind the package with a privileged binder ID
Example (conceptual):
- Run `DSN SYSTEM(DBDG)` under an ID that has **BINDADD** (or higher).
- Bind the package into your collection.

```
BIND PACKAGE(Z88011COLL)
     MEMBER(LIBMQCIC)
     ACTION(REPLACE)
     QUALIFIER(Z88011)
     OWNER(Z88011)
     ISOLATION(CS)
     RELEASE(COMMIT)
     VALIDATE(BIND)
     ENCODING(EBCDIC)
```

> Tip: Many shops keep `OWNER(runtime-id)` but **binder-id is different** (the job runs under binder-id, but OWNER/QUALIFIER are set to runtime values).

#### B) Grant runtime EXECUTE so CICS can run SQL
After bind, DB2 must allow the runtime authid to execute the package(s).  
Depending on site standards, this is done with one of these (examples only):

- `GRANT EXECUTE ON PACKAGE <collection>.* TO <runtime-authid>`
- or execute via a role / group

(Exact GRANT syntax and whether you grant at **collection** or **package** level depends on your security setup.)

#### C) Bind the plan with PKLIST (also with privileged binder ID)
Your earlier plan bind warning was:

`DSNT241I ... AUTHORIZATION-ID Z88011 NOT AUTHORIZED TO EXECUTE PACKAGE Z88011COLL.*`

This is a runtime permission issue: the plan may be bound, but the runtime authid can’t execute packages in that collection.

Plan bind example:

```
BIND PLAN(Z88011PLAN)
     PKLIST(Z88011COLL.*)
     ACTION(REPLACE)
     ISOLATION(CS)
     ENCODING(EBCDIC)
     VALIDATE(RUN)
```

Then ensure runtime EXECUTE on the packages/collection.

### Quick checklist
- [ ] **Binder ID** has **BINDADD** (or higher) for the target subsystem/collection/database.
- [ ] Package successfully bound into **collection** you reference in the plan `PKLIST(...)`.
- [ ] Runtime authid (CICS side) has **EXECUTE** on packages/collection.
- [ ] Plan successfully bound and includes the right `PKLIST(...)`.
- [ ] CICS DB2 resources (DB2CONN/DB2ENTRY/DB2TRAN) point to the correct **plan** and **authid**.

### Where to fix it
- If you want `Z88011` to bind packages itself: ask DB2/security admin to grant **BINDADD** (or make you run the bind under a privileged “binder” ID).
- If bind should be restricted (common in CI/CD): keep `Z88011` as runtime only and run binds under a controlled binder ID.
