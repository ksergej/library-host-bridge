# operator_cheat_sheet_LIBT_MQCONN.md

## LIBT / LIBMQCIC — MQCONN operator cheat sheet

### Goal
Bring up the CICS `MQCONN` resource for queue manager `CSQ9` and re-test transaction `LIBT`.

---

## 1) Define MQCONN

Command:

```text
CEDA DEF MQCONN(MQC9) GROUP(Z88011)
```

Fill panel:

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

## 2) Install MQCONN

Command:

```text
CEDA INSTALL MQCONN(MQC9) GROUP(Z88011)
```

Expected:

```text
INSTALL SUCCESSFUL
```

---

## 3) Verify installed state

Command:

```text
CEMT I MQCONN
```

Expected before connect:

```text
Mqname( CSQ9 )
Connectst( Notconnected )
RESPONSE: NORMAL
```

---

## 4) Connect MQCONN

Command:

```text
CEMT SET MQCONN CONNECTED
```

Then verify again:

```text
CEMT I MQCONN
```

Target:

```text
Connectst( Connected )
```

---

## 5) Re-test program

Command:

```text
LIBT
```

Watch terminal output.

Good examples:

```text
MQCONN OK CC=0 RC=0
MQOPEN REQ OK ...
```

Current known bad example:

```text
MQOPEN REQ FAIL CC=2 RC=2204
```

Meaning:
- `2204 = adapter not available`
- definition exists, but region-level CICS↔MQ path is still not fully operational

---

## 6) If CONNECT fails

If you see:

```text
SET FAILED
RESPONSE: 1 ERROR
```

Do this:

### 6.1 Check message text
On the failure screen:

```text
PF9 MSG
```

Capture the exact message.

### 6.2 Re-check runtime state

```text
CEMT I MQCONN
```

Typical current state:

```text
Mqname( CSQ9 )
Mqqmgr(CSQ9)
Connectst( Notconnected )
```

### 6.3 Check region startup PROC
Most likely cause in this project:
- missing MQ libraries in CICS startup PROC / JCL

Required pattern:

#### STEPLIB
```jcl
//STEPLIB   DD DISP=SHR,DSN=DFH620.CICS.SDFHAUTH
//          DD DISP=SHR,DSN=DFH620.CICS.SDFHLINK
//          DD DISP=SHR,DSN=DFH620.CPSM.SEYUAUTH
//          DD DISP=SHR,DSN=DFH620.SDFHLIC
//          DD DISP=SHR,DSN=<MQ.HLQ>.SCSQAUTH
```

#### DFHRPL
```jcl
//DFHRPL   DD DSN=DFH620.CPSM.SEYULOAD,DISP=SHR
//         DD DSN=DFH620.CICS.SDFHLOAD,DISP=SHR
//         DD DSN=<MQ.HLQ>.SCSQLOAD,DISP=SHR
//         DD DSN=<MQ.HLQ>.SCSQAUTH,DISP=SHR
//*        DD DSN=<MQ.HLQ>.SCSQCICS,DISP=SHR
```

Replace `<MQ.HLQ>` with the real MQ dataset HLQ on your system.

Restart region after PROC change.

Then re-run:

```text
CEMT I MQCONN
CEMT SET MQCONN CONNECTED
CEMT I MQCONN
LIBT
```

---

## 7) Batch / JCL alternative

### Define via DFHCSDUP

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

### List group

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

### Practical hybrid sequence

1. Batch:
```jcl
DEFINE MQCONN(MQC9) GROUP(Z88011) MQNAME(CSQ9) RESYNCMEMBER(YES)
```

2. Online:
```text
CEDA INSTALL MQCONN(MQC9) GROUP(Z88011)
CEMT I MQCONN
CEMT SET MQCONN CONNECTED
CEMT I MQCONN
```

---

## 8) Fast copy/paste summary

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
