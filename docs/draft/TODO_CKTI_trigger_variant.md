# TODO_CKTI_trigger_variant.md

## Short todo-list: MQ starts CICS transaction via CKTI

Goal:
Move from manual `LIBT` start to event-driven start where MQ trigger
causes CICS transaction `LIBT` to start automatically.

References:
- CKTI starts a CICS transaction when it reads an MQ trigger message. citeturn144907search0turn144907search1
- `MQMONITOR` is the recommended way to control CKTI. citeturn144907search3turn144907search10
- CKTI can be started manually with `CKQC STARTCKTI`. citeturn144907search3turn144907search9

---

## 1) Freeze the current manual baseline

Before trigger work, keep the already working manual path as reference:

- `LIBT` manual start works
- `MQCONN` connected
- `DB2CONN` connected
- request/reply flow works end-to-end
- `borrow` already returns real `loanId`

This is rollback baseline.

---

## 2) Choose the trigger model

Use the standard model:

- application queue = current request queue
- initiation queue = separate queue for trigger messages
- CKTI listens on initiation queue
- CKTI starts `LIBT`
- `LIBT` then does `MQGET` from application queue

Important:
`LIBT` must still read the real business message from the application
queue, not from the initiation queue. citeturn144907search1turn144907search3

---

## 3) Define MQ objects on MQ side

Needed MQ objects:

- application queue  
  example: `Z88011.MQZ3.QLOCAL`
- reply queue  
  example: `Z88011.MQZ3.REPLYTO.QLOCAL`
- initiation queue for triggers  
  example: `Z88011.MQZ3.INITQ`
- process definition for triggered app  
  example: `Z88011.MQZ3.LIBT.PROCESS`

Todo:
- enable triggering on application queue
- point it to initiation queue
- attach process definition
- set application type to CICS

Result:
when a message is put on the application queue, MQ writes a trigger
message to the initiation queue. citeturn144907search1turn144907search3

---

## 4) Decide what CICS transaction CKTI should start

Target transaction:
- `LIBT`

Todo:
- confirm `LIBT` is the transaction to be started by trigger
- confirm `LIBMQCIC` remains the target program behind `LIBT`
- confirm `LIBT` can run non-terminal / triggered safely

Recommended:
- add a small trace message showing whether start source is manual or
  CKTI-triggered
- optional: use `EXEC CICS RETRIEVE RTRANSID` to detect `CKTI` start
  path. citeturn144907search0

---

## 5) Define CICS MQMONITOR resource

Recommended method:
use `MQMONITOR` to control CKTI. citeturn144907search3turn144907search10turn144907search13

Todo:
- define `MQMONITOR` in CICS
- set it to watch the initiation queue
- use CKTI as the trigger monitor transaction
- choose `MONUSERID` carefully

Why:
- `MQMONITOR` is the recommended control path for CKTI
- it gives stable user ID behavior for security. citeturn144907search12

Suggested naming:
- `MQMONITOR(LIBTMON)` in group `Z88011`

---

## 6) Install and start MQMONITOR / CKTI

Todo:
- ensure `MQCONN` is already installed and connected
- install `MQMONITOR`
- start `MQMONITOR`
- verify CKTI is active

Manual alternatives:
- `CKQC STARTCKTI`
- `CKQC STARTCKTI <initiation-queue>` citeturn144907search3turn144907search9

Preferred:
- `MQMONITOR`, not raw `CKQC`, especially if security matters. citeturn144907search12

---

## 7) Security / user ID review

Critical todo:
decide under which user ID CKTI and started `LIBT` should run.

Reason:
the user ID of CKTI can propagate to started transactions, and that user
must have access to MQ queues and any required CICS/DB2 resources. citeturn144907search3turn144907search12

Checklist:
- MQ queue access
- CICS transaction/program access
- DB2 plan/package access if DB2 logic stays enabled

---

## 8) Adapt `LIBMQCIC` for trigger mode

Current manual mode:
- transaction starts
- program does `MQGET WAIT`

Trigger mode target:
- transaction starts because MQ trigger fired
- program does `MQGET` on application queue
- same request parsing
- same DB2 logic
- same reply queue / `CorrelId`

Todo:
- keep reply logic unchanged
- keep `CorrelId = request MsgId`
- consider reducing `WAIT_MS` because trigger mode should start only
  when there is work
- verify no terminal-only assumptions remain

---

## 9) Test path in phases

### Phase A
Keep DB2 disabled, trigger only.

Test:
- put a request on application queue
- verify trigger message appears on initiation queue
- verify CKTI starts `LIBT`
- verify `LIBT` consumes app message
- verify stub reply is produced

### Phase B
Enable real DB2 logic.

Test:
- `borrow`
- `return`
- `active loans by user`

### Phase C
Negative and operational tests.

Test:
- duplicate borrow
- invalid loanId
- invalid user/book
- empty queue
- multiple messages
- restart region and recover

---

## 10) Operator checklist after region restart

Recommended sequence:

```text
CEMT I MQCONN
CEMT I DB2CONN
```

If resources are missing:

```text
CEDA INSTALL GROUP(Z88011)
```

Then:

```text
CEMT I MQCONN
CEMT I DB2CONN
```

If needed:

```text
CEMT SET MQCONN CONNECTED
CEMT SET DB2CONN DB2ID(DBDG)
CEMT SET DB2CONN CONNECTED
```

Then for trigger variant:
- ensure `MQMONITOR` is installed
- ensure `MQMONITOR` is started
- or manually start CKTI if doing bring-up

Example manual start path:

```text
CKQC STARTCKTI
```

or

```text
CKQC STARTCKTI Z88011.MQZ3.INITQ
```

---

## 11) Minimal implementation order

Best order:

1. keep current manual path untouched
2. create initiation queue + process definition on MQ side
3. define/install `MQMONITOR`
4. start CKTI
5. test trigger -> `LIBT` start with DB2 off
6. verify reply path and `CorrelId`
7. enable DB2 logic
8. verify end-to-end business cases

---

## 12) Expected final architecture

```text
Client -> MQ application queue
       -> MQ trigger message -> initiation queue
       -> CKTI / MQMONITOR
       -> CICS starts LIBT
       -> LIBMQCIC MQGET from application queue
       -> DB2 logic
       -> MQPUT reply
```
