# Host XML ↔ Copybook Transformer (LIBMQTST)

Scope: host-side transformation for borrowBook. Java sends/receives XML per `library-loan.xsd`; host converts XML to copybook (`LIBLOAN.cpy`), runs the loan engine (DB2), and converts the copybook response back to XML. MQMD CorrelId=MsgId pattern remains unchanged (CorrelationId is NOT in the payload).

## XML shapes (aligned with XSD / Java JAXB)
Request:
```
<HostBorrowRequest>
  <userId>U000000001</userId>
  <bookId>B000000001</bookId>
</HostBorrowRequest>
```

Response:
```
<HostBorrowResponse>
  <loanId>L000000123</loanId>         <!-- derived from LOAN_ID_NUM identity -->
  <userId>U000000001</userId>
  <bookId>B000000001</bookId>
  <statusCode>OK|BUSY|ERR</statusCode>
  <message>...</message>
</HostBorrowResponse>
```

## Where the logic lives (LIBMQTST.cbl)
- `PARSE-XML-REQUEST`: extracts `<userId>` and `<bookId>` into HOST-BORROW-REQUEST (LIBLOAN.cpy). On parse error: sets `HBR-STATUS-CODE='ERR'`, `HBR-MESSAGE='Invalid XML'`.
- `PROCESS-REQUEST`: business logic/DB2 (borrow engine). Uses copybook request; fills copybook response. Generates LOAN_ID_NUM identity, derives external `HBR-LOAN-ID = 'L' + zero-padded LOAN_ID_NUM`.
- `BUILD-XML-RESPONSE`: builds `<HostBorrowResponse>` XML from copybook response fields.
- MQ flow: MQGET payload (XML) → `PARSE-XML-REQUEST` → `PROCESS-REQUEST` → `BUILD-XML-RESPONSE` → MQPUT payload (XML). MQMD CorrelId=MsgId unchanged.

## Notes
- Copybook `LIBLOAN.cpy` is unchanged (HOST-BORROW-REQUEST/RESPONSE).
- DB2 schema uses LOAN_ID_NUM (IDENTITY PK). External loanId is derived; it is not stored in the table (see view `V_LOAN` for debugging).
- CorrelationId stays in MQMD headers only; it is not part of XML or the copybook.
