      *****************************************************************
      * Host loan request/response payload (MQ message body only)
      * CorrelationId remains in MQMD (CorrelId = MsgId) — do not add
      * correlation fields here.
      *****************************************************************
       01  HOST-BORROW-REQUEST.
           05 HBR-USER-ID        PIC X(10).
           05 HBR-BOOK-ID        PIC X(10).
           05 HBR-REQUESTED-DUE  PIC X(10).
           05 HBR-RESERVED       PIC X(30).

       01  HOST-BORROW-RESPONSE.
           05 HBR-LOAN-ID        PIC X(10).
           05 HBR-USER-ID-R      PIC X(10).
           05 HBR-BOOK-ID-R      PIC X(10).
           05 HBR-STATUS-CODE    PIC X(4).
           05 HBR-MESSAGE        PIC X(80).
           05 HBR-RESERVED-R     PIC X(40).
