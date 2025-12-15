# Host Loan Payload Alignment Plan (P15)

Scope: design-only. No code or JCL is changed here. The existing MQMD correlation pattern stays as-is.

## MQMD Correlation (unchanged, do not modify)
- Java side: send request, read `JMSMessageID`, then read reply with selector `JMSCorrelationID = <JMSMessageID>`.
- Host side (COBOL): `MOVE MQMD-MSGID TO MQMD-CORRELID` and `MOVE MQMI-NONE TO MQMD-MSGID` (CorrelId = MsgId).
- CorrelationId is **not** part of the payload/copybook; it remains only in MQMD headers.

## Options recap (from host-xml-mapping-analysis)
- A: COBOL handles XML directly.
- B: Host-side transformer: copybook ↔ XML on host.
- C: Change Java/XSD to flat layout (no XML on MQ).

### Recommended option: **B (host-side transformer)**
- Preserves current Java contract (JAXB/XSD, REST/OpenAPI, frontend).
- Keeps COBOL logic on a flat/copybook-friendly structure; avoids full XML parsing in core business code.
- Allows incremental rollout: add transformer step without breaking existing Java side.
- Correlation pattern remains untouched (MQMD headers only).

## Proposed copybook layout (payload only)

Request (from Java to host):
```
01  HOST-BORROW-REQUEST.
    05 HBR-USER-ID        PIC X(20).
    05 HBR-BOOK-ID        PIC X(20).
    05 HBR-REQUESTED-DUE  PIC X(10).   *> YYYY-MM-DD or spaces (optional)
    05 HBR-RESERVED       PIC X(30).   *> filler/reserved
```

Response (from host to Java):
```
01  HOST-BORROW-RESPONSE.
    05 HBR-LOAN-ID        PIC X(20).
    05 HBR-USER-ID        PIC X(20).
    05 HBR-BOOK-ID        PIC X(20).
    05 HBR-STATUS-CODE    PIC X(4).    *> e.g. "OK", "ERR"
    05 HBR-MESSAGE        PIC X(80).   *> optional text
    05 HBR-RESERVED       PIC X(40).
```

### Mapping table (payload ↔ XML ↔ Java domain)

| COBOL field        | XML element                           | Java domain (Loan)      | Notes                              |
|--------------------|---------------------------------------|-------------------------|------------------------------------|
| HBR-USER-ID        | HostBorrowRequest/user/id             | Loan.userId             | Required                           |
| HBR-BOOK-ID        | HostBorrowRequest/book/id             | Loan.bookId             | Required                           |
| HBR-REQUESTED-DUE  | HostBorrowRequest/requestedDueDate    | (ignored today)         | Optional; spaces if unused         |
| HBR-LOAN-ID        | HostBorrowResponse/loan/loanId        | Loan.id                 | Optional in response               |
| HBR-USER-ID        | HostBorrowResponse/loan/user/id       | Loan.userId             | Echo/back from host                |
| HBR-BOOK-ID        | HostBorrowResponse/loan/book/id       | Loan.bookId             | Echo/back from host                |
| HBR-STATUS-CODE    | HostBorrowResponse/status             | n/a in domain today     | "OK"/"ERR"                         |
| HBR-MESSAGE        | HostBorrowResponse/message            | n/a in domain today     | Optional text                      |

## Payload flow (headers are separate)
- **Java → MQ → Host (request):**
  - On the wire: XML per `library-loan.xsd`.
  - Host transformer (new) converts XML → copybook `HOST-BORROW-REQUEST` for COBOL business logic.
  - MQMD correlation stays as in PROJECT_CONTEXT (CorrelId = MsgId).
- **Host → MQ → Java (response):**
  - COBOL produces copybook `HOST-BORROW-RESPONSE`.
  - Transformer converts copybook → XML per `HostBorrowResponse`.
  - Java unmarshals XML via JAXB and maps to domain `Loan`.

## Implementation roadmap (future tasks)
1) Add host copybook (e.g., `HOSTLOAN.cpy`) with the structures above; refactor `LIBMQTST.cbl` (or successor) to use structured fields instead of flat buffers.
2) Implement host-side XML ↔ copybook transformer (could be a separate module/step or integrated into the MQ program) to keep XML on the wire.
3) Keep Java translator as-is (XML); only adjust if XML field lengths need alignment (e.g., max lengths for IDs).
4) Add end-to-end MQ tests (Java ↔ MQ ↔ COBOL) using the new payload, ensuring CorrelationId (MQMD) still follows CorrelId = MsgId.
5) Update documentation/JCL/Ansible once the transformer and copybook are in place (no change to correlation handling).
