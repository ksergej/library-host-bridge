# runbook_LIBT_MQCONN_DB2CONN_v4.md — CICS MQCONN + DB2CONN runbook for LIBT / LIBMQCIC

Context:
- CICS region APPLID: `CXZ88011` (SYSID `S750`)
- CSD dataset: `Z88011.CICS.DFHCSD`
- Working CICS group: `Z88011`
- MQ queue manager target: `CSQ9`
- DB2 subsystem target: `DBDG`
- COBOL program: `LIBMQCIC`
- CICS transaction: `LIBT`

This runbook covers:
- `MQCONN` define / install / connect
- `DB2CONN` verify / set / connect
- startup and post-restart operator steps
- JCL / batch examples

---

## 1) What MQCONN and DB2CONN are

Two region-level resource paths matter for `LIBT`:

- `MQCONN` = CICS connection resource for IBM MQ
- `DB2CONN` = CICS connection resource for DB2

These are not the same as program-level calls:
- COBOL `CALL 'MQCONN'` is an API call
- embedded SQL is program logic
- `MQCONN` / `DB2CONN` in CICS are region resources and connection states

So `LIBT` can fail even if the program is compiled correctly, when region-level connection state is missing.

---

## 2) MQCONN naming clarification

Example:

```text
CEDA DEF MQCONN(MQC9) GROUP(Z88011)
```

Here:
- `MQC9` = CICS resource definition name
- `Z88011` = CSD group

Inside the panel:

```text
Mqname ==> CSQ9
```

Here:
- `CSQ9` = real MQ queue manager name

So:
- `MQC9` is chosen by you
- `CSQ9` is the real queue manager

---

## 3) DEFINE MQCONN via CEDA

Command:

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

Expected:

```text
DEFINE SUCCESSFUL
```

---

## 4) INSTALL MQCONN

Command:

```text
CEDA INSTALL MQCONN(MQC9) GROUP(Z88011)
```

Expected:

```text
INSTALL SUCCESSFUL
```

---

## 5) VERIFY MQCONN

Command:

```text
CEMT I MQCONN
```

Expected after install, before connect:

```text
Mqname( CSQ9 )
Connectst( Notconnected )
RESPONSE: NORMAL
```

---

## 6) CONNECT MQCONN

Command:

```text
CEMT SET MQCONN CONNECTED
```

Verify again:

```text
CEMT I MQCONN
```

Target:

```text
Connectst( Connected )
Mqqmgr(CSQ9)
Mqrelease(...)
```

If connect fails:
- use `PF9 MSG`
- re-check region startup PROC / JCL MQ libraries

---

## 7) DB2CONN basics

Unlike `MQCONN`, in your region `DB2CONN` already exists.
The first check is not `CEDA DEF DB2CONN`, but:

```text
CEMT I DB2CONN
```

Typical initial state observed:

```text
Connectst( Notconnected )
Db2id(      )
Connecterror( Sqlcode )
```

Important:
- if `Db2id` is blank, CICS may default to `DSN`
- if that subsystem does not exist, connect fails with `DB2ID NOT FOUND`

---

## 8) VERIFY DB2CONN

Command:

```text
CEMT I DB2CONN
```

Useful fields:

```text
Connectst( Notconnected | Connected )
Db2id( DBDG )
Db2release(...)
Connecterror(...)
```

Interpretation:
- `Notconnected` = CICS is not yet attached to DB2
- `Db2id(blank)` = DB2 subsystem is not yet set
- `Db2id(DSN)` with failure often means default was used and is wrong for this environment
- `Db2id(DBDG)` = correct subsystem for this project

---

## 9) SET DB2CONN subsystem

For this project the working DB2 subsystem is:

```text
DBDG
```

Set it with:

```text
CEMT SET DB2CONN DB2ID(DBDG)
```

Verify:

```text
CEMT I DB2CONN
```

Expected:

```text
Db2id( DBDG )
```

---

## 10) CONNECT DB2CONN

After `DB2ID` is set correctly:

```text
CEMT SET DB2CONN CONNECTED
```

Verify again:

```text
CEMT I DB2CONN
```

Target state:

```text
Connectst( Connected )
Db2id( DBDG )
Db2release(...)
```

This confirms the region-level CICS↔DB2 connection path is active.

---

## 11) Alternative DB2 start command

Alternative to the CEMT path:

```text
DSNC STRT DBDG
```

Use this if your site prefers the standard DB2 attachment transaction path.

But in your current work, the successful operational sequence was:

```text
CEMT SET DB2CONN DB2ID(DBDG)
CEMT SET DB2CONN CONNECTED
```

---

## 12) Full operator sequence: MQ + DB2 + LIBT

Use this after region restart.

### 12.1 Check MQ

```text
CEMT I MQCONN
```

If:

```text
Connectst( Notconnected )
```

then:

```text
CEMT SET MQCONN CONNECTED
```

### 12.2 Check DB2

```text
CEMT I DB2CONN
```

If `Db2id` is blank or wrong:

```text
CEMT SET DB2CONN DB2ID(DBDG)
```

If:

```text
Connectst( Notconnected )
```

then:

```text
CEMT SET DB2CONN CONNECTED
```

### 12.3 Run application

```text
LIBT
```

---

## 13) Practical interpretation of recent failures

### Symptom A
Program abended with:

```text
DFHAC2206 ... Transaction LIBT failed with abend ASRA
```

when the first SQL statement was added.

### What that meant here
It was not enough to look at the SQL statement itself.
The real issue was that `DB2CONN` was still not connected.

### Result after DB2CONN fix
After:

```text
CEMT SET DB2CONN DB2ID(DBDG)
CEMT SET DB2CONN CONNECTED
```

the DB2 region path became available.

This puts DB2 in the same operational category as MQ:
- after restart, connection state must be checked
- if not connected, connect it before running `LIBT`

---

## 14) MQ startup JCL / PROC additions

Your region needed MQ libraries in startup JCL / PROC.

### STEPLIB

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

### DFHRPL

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

DB2 runtime libraries were already present in your region startup path, so the main DB2 issue turned out to be connection state, not startup library absence.

---

## 15) Batch / JCL alternative for MQCONN definition

### DEFINE MQCONN via DFHCSDUP

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

### LIST group

```jcl
//MQCLIST  EXEC PGM=DFHCSDUP,REGION=1M
//STEPLIB  DD DISP=SHR,DSN=DFH620.CICS.SDFHLOAD
//DFHCSD   DD DISP=SHR,DSN=Z88011.CICS.DFHCSD
//SYSPRINT DD SYSOUT=*
//SYSDUMP  DD SYSOUT=*
//SYSIN    DD *
  LIST GROUP(Z88011)
/*
```

---

## 16) DB2CONN note

In your current region, `DB2CONN` already exists and is visible through `CEMT I DB2CONN`.
So the normal operator path is:
- inspect it
- set `DB2ID`
- connect it

If later you need CSD-admin work for DB2 resources, handle that separately, but it is not required for the current operator runbook.

---

## 17) Fast post-restart checklist

After region restart do this:

```text
CEMT I MQCONN
CEMT I DB2CONN
```

If MQ shows `Notconnected`:

```text
CEMT SET MQCONN CONNECTED
```

If DB2 shows wrong or blank `Db2id`:

```text
CEMT SET DB2CONN DB2ID(DBDG)
```

If DB2 shows `Notconnected`:

```text
CEMT SET DB2CONN CONNECTED
```

Then:

```text
LIBT
```

---

## 18) Fast copy/paste summary

```text
CEMT I MQCONN
CEMT I DB2CONN

CEMT SET MQCONN CONNECTED
CEMT SET DB2CONN DB2ID(DBDG)
CEMT SET DB2CONN CONNECTED

LIBT
```

Use the `SET` commands only when the corresponding `INQUIRE` shows they are needed.

---

## 19) Current working baseline

Confirmed:
- `MQCONN` defined and installed
- `MQCONN` can be connected to `CSQ9`
- `DB2CONN` exists
- `DB2ID(DBDG)` can be set
- `DB2CONN` can be connected
- region-level MQ and DB2 paths are now both operational
- next debugging layer is program SQL/runtime behavior, not missing region connection state
