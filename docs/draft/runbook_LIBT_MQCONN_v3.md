# runbook_LIBT_MQCONN_v3.md — CICS MQCONN define/install/connect runbook for LIBT / LIBMQCIC

Context:
- CICS region APPLID: `CXZ88011` (SYSID `S750`)
- CSD dataset: `Z88011.CICS.DFHCSD`
- Working CICS group for this effort: `Z88011`
- MQ queue manager target: `CSQ9`
- COBOL program: `LIBMQCIC`
- CICS transaction: `LIBT`
- Current symptom already observed:
  - `MQCONN OK CC=0 RC=0`
  - `MQOPEN REQ FAIL CC=2 RC=2204`
- Meaning of the above symptom in this runbook:
  - MQ API linkage exists
  - but CICS↔MQ adapter / region connection path is not fully connected yet

This runbook extends the earlier LIBT runbook with the full `MQCONN` path:
- `DEFINE MQCONN`
- `INSTALL MQCONN`
- `CONNECT MQCONN`
- runtime verification
- startup considerations
- JCL alternatives using `DFHCSDUP`

---

## 1) What MQCONN is

`MQCONN` in CICS is a **CICS resource definition**, not the same thing as the COBOL `CALL 'MQCONN'` API call.

Think of it like this:
- `CALL 'MQCONN'` in COBOL = application API call
- `MQCONN` resource in CICS = region-level configuration object that tells CICS which MQ manager it should connect to

Important consequences:
- you must `DEFINE` and `INSTALL` an `MQCONN` resource before CICS can manage the MQ connection correctly
- only **one installed MQCONN** can exist at a time in a region
- `CEMT SET MQCONN CONNECTED` works only if an `MQCONN` resource is already installed

---

## 2) Naming clarification: MQCONN name vs MQNAME

This is the most common source of confusion.

Example:

```text
CEDA DEF MQCONN(MQC9) GROUP(Z88011)
```

Here:
- `MQC9` = **name of the CICS resource definition**
- `Z88011` = CSD group

Inside the panel, you must separately set:

```text
Mqname ==> CSQ9
```

Here:
- `CSQ9` = **actual MQ queue manager name**

So:
- `MQC9` is chosen by you
- `CSQ9` is the real queue manager

Recommended naming:
- resource name: `MQC9` or `MQCSQ9`
- queue manager: `CSQ9`

---

## 3) Preconditions

Before working on `MQCONN`, verify:

1. You can enter `CEDA`.
2. You can enter `CEMT`.
3. Region is running and you are logged on.
4. Your CICS group `Z88011` is available in CSD.
5. Your COBOL path already works at least for simple terminal output, for example:
   - `LIBT`
   - `LIBMQCIC OK`
6. MQ libraries for CICS are planned in region startup JCL / PROC.

---

## 4) DEFINE MQCONN interactively via CEDA

### 4.1 Enter command

From a clean CICS command line:

```text
CEDA DEF MQCONN(MQC9) GROUP(Z88011)
```

### 4.2 Fill the panel

Set fields like this:

```text
MQConn         : MQC9
Group          : Z88011
Mqname       ==> CSQ9
Resyncmember ==> Yes
Initqname    ==> 
```

Notes:
- `MQConn` = local CICS resource name
- `Mqname` = real MQ manager name
- `Resyncmember = Yes` is a good safe baseline
- `Initqname` can stay blank for your current request/reply path; it is not required for the current `MQGET` / `MQPUT` flow

### 4.3 Save definition

Press `Enter`.

Expected result:

```text
DEFINE SUCCESSFUL
```

---

## 5) INSTALL MQCONN interactively via CEDA

After `DEFINE`, install the resource:

```text
CEDA INSTALL MQCONN(MQC9) GROUP(Z88011)
```

Expected result:

```text
INSTALL SUCCESSFUL
```

If CEDA brings you to the generic install panel, ensure the requested type is really `MQCONN` and the group is `Z88011`.

---

## 6) Verify MQCONN via CEMT

Run:

```text
CEMT I MQCONN
```

Expected after install, before connect:

```text
Mqname( CSQ9 )
Connectst( Notconnected )
Tasks(0000)
Trigmontasks(0000)
RESPONSE: NORMAL
```

Interpretation:
- the region sees the `MQCONN` resource
- it points to `CSQ9`
- but the connection is not yet active

---

## 7) CONNECT MQCONN via CEMT

Run:

```text
CEMT SET MQCONN CONNECTED
```

Then verify again:

```text
CEMT I MQCONN
```

Target state:

```text
Connectst( Connected )
```

Possible fields that may also become more informative:
- `Mqqmgr(CSQ9)`
- `Mqrelease(...)`

---

## 8) If CONNECT fails

If you see:

```text
SET FAILED
RESPONSE: 1 ERROR
```

then the `MQCONN` definition itself now exists, but the **region-level CICS↔MQ path is still not operational**.

### 8.1 First check messages

From that failure screen, use:
- `PF9 MSG`

Capture the exact DFH / CKQ / MQ related message text.

### 8.2 Re-check current runtime state

Run:

```text
CEMT I MQCONN
```

Typical state in your current scenario:

```text
Mqname( CSQ9 )
Mqqmgr(CSQ9)
Connectst( Notconnected )
```

### 8.3 Most likely cause in this project

Based on the observed path so far, the most likely remaining cause is region startup configuration, especially missing MQ libraries in CICS startup JCL / PROC.

See the dedicated JCL section below.

---

## 9) Full operator command sequence (interactive)

Use this exact sequence for a clean define/install/connect cycle.

### 9.1 Define

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

Press `Enter`.

### 9.2 Install

```text
CEDA INSTALL MQCONN(MQC9) GROUP(Z88011)
```

### 9.3 Verify installed state

```text
CEMT I MQCONN
```

### 9.4 Connect

```text
CEMT SET MQCONN CONNECTED
```

### 9.5 Verify connected state

```text
CEMT I MQCONN
```

### 9.6 Test application

```text
LIBT
```

If `LIBT` still fails, capture the exact terminal message, including:
- `CC`
- `RC`

---

## 10) Suggested troubleshooting flow for LIBT / LIBMQCIC

### 10.1 CICS base path

```text
CEMT I TRANS(LIBT)
CEMT I PROG(LIBMQCIC)
```

### 10.2 MQCONN resource path

```text
CEMT I MQCONN
CEMT SET MQCONN CONNECTED
CEMT I MQCONN
```

### 10.3 Program path

Run `LIBT` and look at terminal output.

Examples:
- `MQCONN OK CC=0 RC=0`
- `MQOPEN REQ FAIL CC=2 RC=2204`

Interpretation used in this project:
- `MQCONN OK` + `MQOPEN RC=2204` strongly suggests the adapter / region connection is not fully available yet

---

## 11) Startup persistence / auto-availability

There are two different things to keep in mind.

### 11.1 Persisting the definition

`DEFINE MQCONN ... GROUP(Z88011)` writes the definition into CSD.
That is persistent.

### 11.2 Having it installed after region start

`INSTALL` is runtime state.
After a restart, the resource must either:
- be installed automatically through startup group processing, or
- be installed manually again

So for startup automation, the `MQCONN` resource should be kept in a group that is really installed at region startup.

In your current project that likely means:
- keep `MQCONN(MQC9)` in `GROUP(Z88011)` **only if** `Z88011` is already part of the startup path
- otherwise move it to the actual startup group used by the region

### 11.3 Connection state after startup

Even if `MQCONN` is installed, it can still be:

```text
Connectst( Notconnected )
```

So “resource installed” and “connection active” are different steps.

---

## 12) JCL / batch alternative using DFHCSDUP

This section gives examples for defining/installing the `MQCONN` resource through batch JCL instead of interactive `CEDA`.

These examples are meant as operator/admin alternatives.

### 12.1 Define MQCONN via DFHCSDUP

Example job step:

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

Notes:
- `MQC9` = CICS resource name
- `CSQ9` = real queue manager name
- `INITQNAME` omitted intentionally for current MVP path

### 12.2 Inspect group via DFHCSDUP

A simple inspection example:

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

Operational note:
- `DFHCSDUP` changes the CSD definition repository
- actual runtime `INSTALL` into the region is often still done with `CEDA INSTALL GROUP(...)` or through region startup processing

So in practice, the most reliable hybrid flow is:
1. batch `DEFINE` with `DFHCSDUP`
2. online `CEDA INSTALL GROUP(Z88011)` or `CEDA INSTALL MQCONN(MQC9) GROUP(Z88011)`
3. online `CEMT SET MQCONN CONNECTED`

### 12.3 Example admin sequence split by responsibility

#### Batch/admin side

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

#### Online/operator side

```text
CEDA INSTALL MQCONN(MQC9) GROUP(Z88011)
CEMT I MQCONN
CEMT SET MQCONN CONNECTED
CEMT I MQCONN
```

### 12.4 Full batch alternative with CEDA-style install via CSD group

If your operational model prefers preparing CSD in batch and installing the group later online, use:

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
  LIST MQCONN(MQC9) GROUP(Z88011)
/*
```

Then online:

```text
CEDA INSTALL GROUP(Z88011)
CEMT I MQCONN
CEMT SET MQCONN CONNECTED
```

---

## 13) JCL / PROC startup additions for CICS-MQ adapter

Your current region PROC is the next important place to check if `SET MQCONN CONNECTED` fails.

### 13.1 Why this matters

You already proved:
- `MQCONN` resource can be defined and installed
- `CEMT I MQCONN` shows `Mqname(CSQ9)`

But connect still failed.

That strongly suggests the region startup environment is not yet fully prepared for CICS↔MQ runtime.

### 13.2 MQ libraries to add to region startup PROC

Based on the current project findings, check that the region startup PROC includes MQ libraries in the right places.

#### In `STEPLIB`

Add MQ authorization library, using your actual MQ HLQ:

```jcl
//STEPLIB   DD DISP=SHR,DSN=DFH620.CICS.SDFHAUTH
//          DD DISP=SHR,DSN=DFH620.CICS.SDFHLINK
//          DD DISP=SHR,DSN=DFH620.CPSM.SEYUAUTH
//          DD DISP=SHR,DSN=DFH620.SDFHLIC
//          DD DISP=SHR,DSN=<MQ.HLQ>.SCSQAUTH
//          DD DISP=SHR,DSN=DSND10.SDSNLOAD
//          DD DISP=SHR,DSN=DSND10.SDSNLOD2
//          DD DISP=SHR,DSN=CEE.SCEERUN2
//          DD DISP=SHR,DSN=CEE.SCEERUN
```

#### In `DFHRPL`

Add MQ load libraries:

```jcl
//DFHRPL   DD DSN=DFH620.CPSM.SEYULOAD,DISP=SHR
//         DD DSN=DFH620.CICS.SDFHLOAD,DISP=SHR
//         DD DSN=<MQ.HLQ>.SCSQLOAD,DISP=SHR
//         DD DSN=<MQ.HLQ>.SCSQAUTH,DISP=SHR
//*        DD DSN=<MQ.HLQ>.SCSQCICS,DISP=SHR
//         DD DSN=ZXP.CICS.PROD.DFHLOAD,DISP=SHR
//         DD DSN=&TSOUID..CICS.PROD.DFHLOAD,DISP=SHR
//         DD DSN=CEE.SCEECICS,DISP=SHR
//         DD DSN=CEE.SCEERUN2,DISP=SHR
//         DD DSN=CEE.SCEERUN,DISP=SHR
```

Notes:
- replace `<MQ.HLQ>` with the real MQ dataset HLQ on your system
- `SCSQCICS` is optional and usually needed only for MQ-supplied sample programs

### 13.3 Startup sequence after PROC change

After JCL / PROC updates:
1. stop the region
2. restart the region
3. run:

```text
CEMT I MQCONN
CEMT SET MQCONN CONNECTED
CEMT I MQCONN
```

4. then rerun:

```text
LIBT
```

---

## 14) Recommended minimum baseline for this project

For the current stage of the project, use this minimum baseline:

### MQCONN resource

```text
Resource name: MQC9
Group        : Z88011
MQNAME       : CSQ9
RESYNCMEMBER : YES
INITQNAME    : blank
```

### Interactive operator sequence

```text
CEDA DEF MQCONN(MQC9) GROUP(Z88011)
CEDA INSTALL MQCONN(MQC9) GROUP(Z88011)
CEMT I MQCONN
CEMT SET MQCONN CONNECTED
CEMT I MQCONN
LIBT
```

### If connect still fails

Check in this order:
1. `PF9 MSG` on the failure screen
2. startup PROC MQ libraries
3. exact MQ HLQ datasets available on the system
4. region startup group path

---

## 15) Quick copy/paste operator summary

```text
CEDA DEF MQCONN(MQC9) GROUP(Z88011)
  MQNAME = CSQ9
  RESYNCMEMBER = YES
  INITQNAME = [blank]

CEDA INSTALL MQCONN(MQC9) GROUP(Z88011)
CEMT I MQCONN
CEMT SET MQCONN CONNECTED
CEMT I MQCONN
LIBT
```

---

## 16) Current project state captured by this runbook

Already confirmed:
- `LIBT` transaction exists and runs `LIBMQCIC`
- minimal CICS terminal path works
- `CALL 'MQCONN'` from program returns `CC=0 RC=0`
- `MQOPEN REQ` failed with `CC=2 RC=2204`
- `MQCONN(MQC9)` was successfully `DEFINE`d and `INSTALL`ed
- `CEMT I MQCONN` shows `Mqname(CSQ9)` and `Connectst(Notconnected)`
- `CEMT SET MQCONN CONNECTED` currently still fails

Therefore the present focus is:
- finish region-level CICS↔MQ connect path
- then retest `MQOPEN`
- then continue with full MQ request/reply flow
- DB2 remains the later step
