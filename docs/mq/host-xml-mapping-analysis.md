# Host MQ Message vs. XML Schema (Analysis)

Scope: analysis only, no code changes. Goal: compare the current host COBOL MQ message format with the XML defined by `library-loan.xsd` and highlight alignment options.

## COBOL message layout (LIBMQTST.cbl)
- Queues: request `LIB.REQ.TEST`, reply `LIB.REP.TEST`.
- Message type: datagram (no reply-to set), wait interval 30s, correlation rule `CorrelId = MsgId`.
- Payload buffers:
  - Request: `REQ-DATA` PIC X(256) (flat 256-byte text).
  - Response: `RSP-DATA` PIC X(256), filled with `"ECHO: " || REQ-DATA`.
- No copybook structure, no field-level parsing, no XML handling. Entire MQ payload is treated as an opaque text block.

## XML schema layout (library-loan.xsd)
- Root elements: `HostBorrowRequest`, `HostBorrowResponse`.
- Request structure:
  - `user` (`id`, `name`, `email`)
  - `book` (`id`, `title`, `author`)
  - `requestedDueDate` (optional `xs:date`)
- Response structure:
  - `loan` (`loanId`, nested `user`, `book`, optional dates/status)
  - `status` (string), `message` (optional string)
- Java mapping:
  - `LoanHostMapper` maps domain `Loan` ↔ JAXB DTOs.
  - `JaxbLibraryMessageTranslator` marshals/unmarshals the above XML to/from `byte[]` over MQ.

## Field mapping comparison

| Concept                | COBOL payload (LIBMQTST)    | XML (XSD) element                    | Java domain field        | Notes |
|------------------------|-----------------------------|--------------------------------------|--------------------------|-------|
| User identifier        | Not present (raw text only) | `HostBorrowRequest/user/id`          | `Loan.userId`            | No structured parsing on host. |
| Book identifier        | Not present                 | `HostBorrowRequest/book/id`          | `Loan.bookId`            | Same as above. |
| requestedDueDate       | Not present                 | `HostBorrowRequest/requestedDueDate` | (ignored in mapper)      | Unused in Java domain and host. |
| Loan info in response  | Not present                 | `HostBorrowResponse/loan`            | `Loan` fields            | Host replies with plain `"ECHO: <input>"`. |
| Status/message         | Not present                 | `HostBorrowResponse/status`, `message` | n/a in domain           | Host does not emit structured status. |
| Correlation            | CorrelId=MsgId              | Not an XML field                     | Tracked in JMS headers   | Already aligned at MQ header level. |

Summary: the COBOL program treats the payload as opaque text; the XSD/Java stack expects structured XML with user/book/loan fields.

## Direction analysis
- Host currently **does not** parse or emit XML; it echoes raw text.
- Java currently **always** sends/receives XML per XSD.
- There is a fundamental format mismatch: MQ payloads are structured XML on the Java side vs. unstructured text on the COBOL side.

## Alignment options (design only)

**Option A — Make COBOL handle XML directly**
- Pros: Single format end-to-end; no extra transformation hop; preserves current Java/XSD design.
- Cons: Requires XML parsing/serialization on z/OS (COBOL or ancillary utility), added complexity/perf overhead.

**Option B — Host-side transformer (copybook ↔ XML)**
- Pros: Keeps COBOL business logic in a flat/copybook-friendly format; transformation isolated in a dedicated step/program; Java/XSD can stay as-is.
- Cons: Extra component to build/maintain; needs clear copybook definition; still requires XML tooling on host or an intermediate service.

**Option C — Align Java/XSD to flat host layout**
- Pros: Simplest on host (continue using flat text/copybook); no XML parsing on host.
- Cons: Loses structured XML contract; frontend/OpenAPI already aligned to XML; rework needed across Java contract/tests.

## Suggested direction (next steps)
- Prefer A or B to preserve the existing XML/OpenAPI contract:
  - Define an explicit host copybook for request/response fields (userId, bookId, status, etc.).
  - Implement a host-side XML ↔ copybook transform (or extend COBOL to parse XML) so MQ carries XML that matches the XSD.
- Defer concrete implementation to a follow-up task (e.g., “Implement host XML handling or transformer”). No code changes made here.
