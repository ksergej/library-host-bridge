# runbook_handoff.md

## CICS + MQ + DB2 handoff runbook for `LIBT` / `LIBMQCIC`

Environment:
- CICS APPLID: `CXZ88011`
- SYSID: `S750`
- CSD: `Z88011.CICS.DFHCSD`
- Working group: `Z88011`
- MQ queue manager: `CSQ9`
- DB2 subsystem: `DBDG`
- Transaction: `LIBT`
- Program: `LIBMQCIC`

---

## 1. End-to-end chain

Current intended path:

```text
REST / MQ client
   ->
REQ queue Z88011.MQZ3.QLOCAL
   ->
CICS transaction LIBT
   ->
COBOL program LIBMQCIC
   ->
MQGET request
   ->
DB2 SQL
   ->
MQPUT reply to Z88011.MQZ3.REPLYTO.QLOCAL
```

Working infrastructure baseline now proven:
- CICS transaction `LIBT` runs
- CICS terminal output works
- MQ connection path works
- DB2 connection path works
- DB2 smoke test `SELECT CURRENT DATE ...` works

---

## 2. What had to be fixed

### 2.1 CICS program looked hung
Root cause:
- no visible terminal output

Fix:
- add `EXEC CICS SEND TEXT`
- use `RESP/RESP2`

### 2.2 MQ path failed with `MQOPEN ... RC=2204`
Root cause:
- region-level CICS↔MQ connection path not active

Fixes:
- define/install `MQCONN`
- add MQ libraries into region startup JCL
- connect MQ after startup

### 2.3 DB2 SQL initially failed with `ASRA`
Root causes:
- `DB2CONN` not connected
- DB2 link-edit stub path incomplete
- then DB2 plan/package/authorization path not yet ready

Fixes:
- connect `DB2CONN`
- install / set `DB2ENTRY`
- install / set `DB2TRAN`
- correct DB2 stub in link-edit
- `BIND PLAN`
- resolve DB2 authorization so smoke test returns `SQLSTATE=00000`

---

## 3. MQ chain

### 3.1 MQCONN resource
Meaning:
- region-level CICS connection resource for IBM MQ

### 3.2 Interactive define/install/connect

#### Define
```text
CEDA DEF MQCONN(MQC9) GROUP(Z88011)
```

Panel values:
```text
MQConn         : MQC9
Group          : Z88011
Mqname       ==> CSQ9
Resyncmember ==> Yes
Initqname    ==> 
```

#### Install
```text
CEDA INSTALL MQCONN(MQC9) GROUP(Z88011)
```

#### Verify
```text
CEMT I MQCONN
```

Expected:
```text
Mqname( CSQ9 )
Connectst( Notconnected | Connected )
```

#### Connect
```text
CEMT SET MQCONN CONNECTED
```

Verify:
```text
CEMT I MQCONN
```

Target:
```text
Connectst( Connected )
Mqqmgr(CSQ9)
Mqrelease(...)
```

### 3.3 MQ JCL / batch example

```jcl
//MQCDEF   EXEC PGM=DFHCSDUP,REGION=1M
//STEPLIB  DD DISP=SHR,DSN=DFH620.CICS.SDFHLOAD
//DFHCSD   DD DISP=SHR,DSN=Z88011.CICS.DFHCSD
//SYSPRINT DD SYSOUT=*
//SYSDUMP  DD SYSOUT=*
//SYSIN    DD *
  DEFINE MQCONN(MQC9) GROUP(Z88011) -
         MQNAME(CSQ9) -
         RESYNCMEMBER(YES)
/*
```

### 3.4 MQ startup JCL requirement
Region startup JCL had to include MQ libraries:

#### STEPLIB
```jcl
//STEPLIB   DD DISP=SHR,DSN=DFH620.CICS.SDFHAUTH
//          DD DISP=SHR,DSN=DFH620.CICS.SDFHLINK
//          DD DISP=SHR,DSN=DFH620.CPSM.SEYUAUTH
//          DD DISP=SHR,DSN=DFH620.SDFHLIC
//          DD DISP=SHR,DSN=CSQ920.SCSQAUTH
//          DD DISP=SHR,DSN=DSND10.SDSNLOAD
//          DD DISP=SHR,DSN=DSND10.SDSNLOD2
//          DD DISP=SHR,DSN=CEE.SCEERUN2
//          DD DISP=SHR,DSN=CEE.SCEERUN
```

#### DFHRPL
```jcl
//DFHRPL    DD DSN=DFH620.CPSM.SEYULOAD,DISP=SHR
//          DD DSN=DFH620.CICS.SDFHLOAD,DISP=SHR
//          DD DSN=ZXP.CICS.PROD.DFHLOAD,DISP=SHR
//          DD DSN=CSQ920.SCSQAUTH,DISP=SHR
//          DD DSN=CSQ920.SCSQLOAD,DISP=SHR
//          DD DSN=&TSOUID..CICS.PROD.DFHLOAD,DISP=SHR
//          DD DSN=CEE.SCEECICS,DISP=SHR
//          DD DSN=CEE.SCEERUN2,DISP=SHR
//          DD DSN=CEE.SCEERUN,DISP=SHR
```

---

## 4. DB2 chain

### 4.1 DB2CONN
Meaning:
- region-level CICS connection resource for DB2

### 4.2 DB2ENTRY
Meaning:
- entry/thread selection definition for DB2 work

### 4.3 DB2TRAN
Meaning:
- transaction-specific DB2 thread selection / mapping

### 4.4 Observed working DB2 connection state
Interactive check:

```text
CEMT I DB2CONN
```

Expected now:
```text
Connectst( Connected )
Db2id( DBDG )
Db2release(...)
```

### 4.5 Interactive DB2 connection steps

#### Check current state
```text
CEMT I DB2CONN
```

#### Set subsystem if needed
```text
CEMT SET DB2CONN DB2ID(DBDG)
```

#### Connect
```text
CEMT SET DB2CONN CONNECTED
```

#### Verify
```text
CEMT I DB2CONN
```

Target:
```text
Connectst( Connected )
Db2id( DBDG )
Db2release(...)
```

Alternative:
```text
DSNC STRT DBDG
```

### 4.6 DB2ENTRY / DB2TRAN
For DB2 SQL in `LIBT`, these were installed to complete the runtime path.

Interactive checks:
```text
CEMT I DB2ENTRY
CEMT I DB2TRAN
```

Typical admin actions if missing:
```text
CEDA DEF DB2ENTRY(...)
CEDA DEF DB2TRAN(...)
CEDA INSTALL GROUP(Z88011)
```

Site-specific attributes depend on local DB2 thread model, but the practical point from this work is:
- after `DB2ENTRY`
- after `DB2TRAN`
- after `BIND PLAN`
- the DB2 smoke test started working

### 4.7 DB2 compile / bind chain

#### Compile job pattern
- CICS translator
- COBOL compile with `PARM='SQL'`
- DBRM output
- link-edit with CICS + DB2 + MQ stubs
- `BIND PLAN`

#### Important link-edit detail
Working idea for CICS + DB2 + MQ:
- `DFHELII` first
- DB2 CICS stub from CICS library
- MQ stub

Example control statements:
```jcl
  INCLUDE CICSLIB(DFHELII)
  INCLUDE CICSLIB(DSNCLI)
  INCLUDE MQLIB(CSQCSTUB)
  ENTRY  LIBMQCIC
  NAME   LIBMQCIC(R)
```

#### Bind example
```jcl
//BIND     EXEC PGM=IKJEFT01,COND=(8,LT,LKED)
//STEPLIB  DD  DSN=DSND10.DBDG.SDSNEXIT,DISP=SHR
//         DD  DSN=DSND10.SDSNLOAD,DISP=SHR
//DBRMLIB  DD  DSN=Z88011.DBRMLIB(LIBMQCIC),DISP=SHR
//SYSUDUMP DD  DUMMY
//SYSTSPRT DD  SYSOUT=*
//SYSPRINT DD  SYSOUT=*
//SYSTSIN  DD  *
 DSN SYSTEM(DBDG)
 BIND PLAN(Z88011) PKLIST(Z88011.*) MEMBER(LIBMQCIC) -
      ACT(REP) ISO(CS) ENCODING(EBCDIC)
/*
```

### 4.8 DB2 diagnostics path
DB2 messages were routed like this:

```text
CDB2 -> CSSL -> MSGUSR
```

Confirmed by:
- `CEMT I TDQUEUE(CDB2)` -> indirect to `CSSL`
- `CEMT I TDQUEUE(CSSL)` -> extrapartition `DDNAME(MSGUSR)`

In practice, `MSGUSR` was not sufficient alone, so SQLCA output (`SQLCODE`, `SQLSTATE`, `SQLERRMC`) was the most useful live diagnostic path.

### 4.9 DB2 smoke test result
Final success output:
```text
DATE=2026-04-07000 SQLSTATE=00000
```

Meaning:
- SQL executed successfully
- DB2 path is working

Formatting of date can be cleaned later; infrastructure result is already good.

---

## 5. After region restart: operator TODO

This is the practical restart checklist.

### 5.1 First check resource state
```text
CEMT I MQCONN
CEMT I DB2CONN
```

### 5.2 Reinstall group if resources are missing
If resources from group `Z88011` are not installed in runtime:

```text
CEDA INSTALL GROUP(Z88011)
```

Use this when needed, not blindly every time.

### 5.3 MQ
If MQ shows:
```text
Connectst( Notconnected )
```

then do:
```text
CEMT SET MQCONN CONNECTED
```

### 5.4 DB2
If DB2 shows blank or wrong subsystem:
```text
CEMT SET DB2CONN DB2ID(DBDG)
```

If DB2 shows:
```text
Connectst( Notconnected )
```

then do:
```text
CEMT SET DB2CONN CONNECTED
```

### 5.5 Then run application
```text
LIBT
```

---

## 6. Is this post-restart sequence correct?

Proposed by you:

```text
CEDA INSTALL GROUP(Z88011)
CEMT SET MQCONN CONNECTED
CEMT SET DB2CONN CONNECTED
```

Answer:
almost correct, but one more check is recommended first.

Recommended safer sequence:

```text
CEMT I MQCONN
CEMT I DB2CONN
```

Then, if resources are missing:
```text
CEDA INSTALL GROUP(Z88011)
```

Then:
```text
CEMT I MQCONN
CEMT I DB2CONN
```

Then, if needed:
```text
CEMT SET MQCONN CONNECTED
CEMT SET DB2CONN DB2ID(DBDG)
CEMT SET DB2CONN CONNECTED
```

Then:
```text
LIBT
```

### Why this is better
- `MQCONN` and `DB2CONN` are region resources; only one installed definition of each exists at a time
- `SET ... CONNECTED` acts on the currently installed resource
- if `DB2ID` is blank or wrong after restart, `DB2CONN CONNECTED` may fail until `DB2ID(DBDG)` is set

---

## 7. Fast copy/paste post-restart checklist

```text
CEMT I MQCONN
CEMT I DB2CONN

CEDA INSTALL GROUP(Z88011)

CEMT I MQCONN
CEMT I DB2CONN

CEMT SET MQCONN CONNECTED
CEMT SET DB2CONN DB2ID(DBDG)
CEMT SET DB2CONN CONNECTED

LIBT
```

Use `INSTALL` and `SET` only when the preceding `INQUIRE` shows they are needed.

---

## 8. Current confirmed working baseline

Confirmed now:
- `LIBT` starts correctly
- `LIBMQCIC` runs in CICS
- MQ request path works
- MQ reply path works
- `MQCONN` works
- `DB2CONN` works
- `DB2ENTRY` installed
- `DB2TRAN` installed
- DB2 SQL smoke test works
- next work is application SQL/business logic, not infrastructure bring-up
