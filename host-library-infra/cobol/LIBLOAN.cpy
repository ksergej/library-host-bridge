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

       01  HOST-RETURN-REQUEST.
           05 HRR-LOAN-ID        PIC X(10).
           05 HRR-RESERVED       PIC X(40).

       01  HOST-RETURN-RESPONSE.
           05 HRR-LOAN-ID-R      PIC X(10).
           05 HRR-USER-ID-R      PIC X(10).
           05 HRR-BOOK-ID-R      PIC X(10).
           05 HRR-STATUS-CODE    PIC X(4).
           05 HRR-MESSAGE        PIC X(80).
           05 HRR-RESERVED-R     PIC X(40).

       01  HOST-ACTIVE-BY-USER-REQUEST.
           05 HAU-USER-ID        PIC X(10).
           05 HAU-RESERVED       PIC X(40).

       01  HOST-ACTIVE-BY-USER-RESPONSE.
           05 HAU-USER-ID-R      PIC X(10).
           05 HAU-STATUS-CODE    PIC X(4).
           05 HAU-MESSAGE        PIC X(80).
           05 HAU-LOAN-COUNT     PIC 9(2) COMP.
           05 HAU-LOANS.
               10 HAU-LOAN OCCURS 50 TIMES.
                   15 HAU-LOAN-ID   PIC X(10).
                   15 HAU-BOOK-ID   PIC X(10).
           05 HAU-RESERVED-R     PIC X(20).
