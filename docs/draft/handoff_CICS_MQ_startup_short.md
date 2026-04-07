# handoff_CICS_MQ_startup_short.md

## Short handoff: CICS + MQ startup problems and solutions

### Scope
This note captures the main problems and fixes we went through to get the CICS region and MQ connection path working for transaction `LIBT` and program `LIBMQCIC`.

---

## 1) Initial symptom

A minimal CICS test program with:

```cobol
EXEC CICS RETURN END-EXEC.
```

looked like it was hanging when started as transaction `LIBT`.

### What we found
- the program itself was not hanging
- the issue was terminal/session behavior and lack of visible output
- `CEMT I TASK TRAN(LIBT)` returned `NOT FOUND`, which showed the task had already ended

### Fix / conclusion
Add explicit terminal output with:

```cobol
EXEC CICS SEND TEXT ...
```

After that we saw visible output like:

```text
LIBMQCIC OK
LIBMQCIC RETURN OK
```

This confirmed that:
- `LIBT` starts correctly
- `LIBMQCIC` runs correctly
- `EXEC CICS RETURN` works normally

---

## 2) Add RESP / RESP2 to CICS commands

### Problem
Without `RESP` / `RESP2`, CICS command failures were harder to diagnose.

### Fix
Add `RESP(WS-RESP)` and `RESP2(WS-RESP2)` to `SEND TEXT` and `RETURN`, and check:

```cobol
IF WS-RESP NOT = DFHRESP(NORMAL)
```

### Result
This gave a controlled way to detect CICS command failures.

---

## 3) First MQ step: MQCONN

### Goal
Extend the working CICS baseline to a minimal MQ step:
- `SEND TEXT`
- `MQCONN`
- display `CC/RC`
- `RETURN`

### Result
`MQCONN` succeeded:

```text
MQCONN OK CC=0 RC=0
```

This proved:
- MQ runtime linkage is available to the program
- the program can call MQ APIs

---

## 4) MQOPEN failed at first

### Symptom
The next step failed on request queue open:

```text
MQOPEN REQ FAIL
```

At first the screen did not show `CC/RC`.

### Root cause of missing diagnostics
The terminal output paragraph used:

```cobol
LENGTH(40)
```

and the message-building logic used `STRING ... DELIMITED BY SIZE` with a large padded source field.

So the tail of the message with `CC=` and `RC=` was cut off.

### Fix
- increase `SEND TEXT LENGTH(...)`
- fix string assembly so that the prefix does not consume the whole field
- show numeric `COMPCODE` and `REASON` explicitly

### Result
After fixing the display logic, the real error appeared:

```text
MQOPEN REQ FAIL CC=000000002 RC=000002204
```

---

## 5) Meaning of MQ RC 2204

### Diagnosis
`CC=2 RC=2204` means:

- `MQCC_FAILED`
- `MQRC_ADAPTER_NOT_AVAILABLE`

### Conclusion
This showed that:
- the queue name was not the main problem
- the CICS↔MQ adapter / region connection path was not fully available yet

---

## 6) MQCONN CICS resource did not exist

### Symptom
Trying to connect the region to MQ failed:

```text
CEMT SET MQCONN CONNECTED
```

with:

```text
NOT FOUND
```

### Meaning
There was no installed `MQCONN` resource in the region.

### Fix
Define a CICS `MQCONN` resource.

Important naming clarification:
- `MQCONN(MQC9)` = name of the CICS resource definition
- `MQNAME(CSQ9)` = actual MQ queue manager name

### Commands used

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

Then:

```text
CEDA INSTALL MQCONN(MQC9) GROUP(Z88011)
CEMT I MQCONN
```

### Result
After install, CICS showed:

```text
Mqname( CSQ9 )
Connectst( Notconnected )
```

So the resource now existed, but the connection was not yet active.

---

## 7) Region startup JCL / PROC was missing correct MQ library path

### Symptom
Even after `MQCONN` was defined and installed, this still failed:

```text
CEMT SET MQCONN CONNECTED
```

### Likely cause
The region startup environment was not fully prepared for CICS↔MQ runtime.

### Fix applied
MQ libraries were added to the region JCL / PROC:

#### STEPLIB
- `CSQ920.SCSQAUTH`

#### DFHRPL
- `CSQ920.SCSQAUTH`
- `CSQ920.SCSQLOAD`

A standalone no-PROC startup job was then built to include the full CICS startup path with those MQ libraries.

### Result
After region restart with the corrected JCL, the connection succeeded.

---

## 8) MQCONN CONNECTED succeeded

### Successful state
After the fixes, this command worked:

```text
CEMT SET MQCONN CONNECTED
```

and `CEMT I MQCONN` showed:

```text
Mqname( CSQ9 )
Mqqmgr(CSQ9)
Mqrelease(0945)
Connectst( Connected )
```

### Meaning
This confirmed:
- `MQCONN` resource exists and is installed
- the CICS region is connected to queue manager `CSQ9`
- the CICS↔MQ adapter path is operational

Important operational rule:
- you do **not** need to run `CEMT SET MQCONN CONNECTED` before every `LIBT`
- only when `CEMT I MQCONN` shows `Connectst(Notconnected)`, typically after region restart or explicit disconnect

---

## 9) MQGET then succeeded

### Result
After the region-level MQ connection was working, `LIBT` progressed further and showed:

```text
MQGET OK LEN= 000000004
```

### Meaning
This proved:
- `MQOPEN` now works
- `MQGET` now works
- the request queue is being read successfully
- the infrastructure problem has been solved and debugging can move to payload/content logic

---

## 10) Main problems and resolutions summary

### Problem A
`LIBT` looked hung.

### Resolution
It was not hanging; terminal output was missing.
Added `EXEC CICS SEND TEXT`.

---

### Problem B
CICS command failures were opaque.

### Resolution
Added `RESP / RESP2` checks.

---

### Problem C
`MQOPEN REQ FAIL` with no visible reason.

### Resolution
Fixed terminal message assembly and display length so `CC/RC` became visible.

---

### Problem D
`MQOPEN REQ FAIL CC=2 RC=2204`.

### Resolution
Diagnosed as `MQRC_ADAPTER_NOT_AVAILABLE`, meaning region-level CICS↔MQ connection was not operational.

---

### Problem E
`CEMT SET MQCONN CONNECTED` returned `NOT FOUND`.

### Resolution
Defined and installed `MQCONN(MQC9)` with `MQNAME(CSQ9)`.

---

### Problem F
`MQCONN` existed but `CONNECTED` still failed.

### Resolution
Added the needed MQ libraries to region startup JCL / PROC and restarted the region.

---

### Problem G
Need to know when to run `CEMT SET MQCONN CONNECTED`.

### Resolution
Only when `CEMT I MQCONN` shows:

```text
Connectst( Notconnected )
```

If it already shows `Connected`, `LIBT` can be started directly.

---

## 11) Working current baseline

Current confirmed working baseline:

- CICS region starts successfully
- transaction `LIBT` runs program `LIBMQCIC`
- terminal output works
- `MQCONN` resource exists:
  - `MQCONN(MQC9)`
  - `MQNAME(CSQ9)`
- `CEMT SET MQCONN CONNECTED` succeeds
- `CEMT I MQCONN` shows `Connectst(Connected)`
- `MQGET` works

Current focus after this baseline:
- inspect actual payload read from the request queue
- complete full MQ request/reply flow
- add DB2 logic last

---

## 12) Core operator commands used

### Define MQCONN
```text
CEDA DEF MQCONN(MQC9) GROUP(Z88011)
```

### Install MQCONN
```text
CEDA INSTALL MQCONN(MQC9) GROUP(Z88011)
```

### Check MQCONN
```text
CEMT I MQCONN
```

### Connect region to MQ
```text
CEMT SET MQCONN CONNECTED
```

### Run application
```text
LIBT
```
