CBL NOXREF NOMAP NOOFFSET NOSOURCE
       IDENTIFICATION DIVISION.
       PROGRAM-ID. LIBMQCIC.

       DATA DIVISION.
       WORKING-STORAGE SECTION.

       01  MQM-CONSTANTS.
           COPY CMQV.

       01  MQM-OBJECT-DESCRIPTOR.
           COPY CMQODV.

       01  MQM-MESSAGE-DESCRIPTOR.
           COPY CMQMDV.

       01  MQM-GET-MESSAGE-OPTIONS.
           COPY CMQGMOV.

       01  MQM-PUT-MESSAGE-OPTIONS.
           COPY CMQPMOV.

       01  WS-RESP                  PIC S9(8) COMP VALUE 0.
       01  WS-RESP2                 PIC S9(8) COMP VALUE 0.

       01  WS-QMGR-NAME             PIC X(48) VALUE 'CSQ9'.
       01  WS-REQ-QUEUE             PIC X(48) VALUE 'Z88011.MQZ3.QLOCAL'.
       01  WS-RPLY-QUEUE            PIC X(48) VALUE 'Z88011.MQZ3.REPLYTO.QLOCAL'.
       01  WS-WAIT-MS               PIC S9(9) COMP VALUE 30000.

       01  HCONN                    PIC S9(9) COMP VALUE 0.
       01  HOBJ-REQ                 PIC S9(9) COMP VALUE 0.
       01  HOBJ-RPLY                PIC S9(9) COMP VALUE 0.
       01  COMPCODE                 PIC S9(9) COMP VALUE 0.
       01  REASON                   PIC S9(9) COMP VALUE 0.

       01  WS-COMPCODE-DISP         PIC -ZZZ,ZZZ,ZZ9.
       01  WS-REASON-DISP           PIC -ZZZ,ZZZ,ZZ9.
       01  WS-WAIT-DISP             PIC -ZZZ,ZZZ,ZZ9.
       01  WS-DATA-LEN-DISP         PIC -ZZZ,ZZZ,ZZ9.

       01  WS-TERM-MSG              PIC X(80) VALUE SPACES.
       01  WS-TERM-MSG2             PIC X(80) VALUE SPACES.

       01  REQ-DATA                 PIC X(4096) VALUE SPACES.
       01  RSP-DATA                 PIC X(4096) VALUE SPACES.
       01  REQ-BUF-LEN              PIC S9(9) COMP VALUE 4096.
       01  REQ-DATA-LEN             PIC S9(9) COMP VALUE 0.
       01  RSP-DATA-LEN             PIC S9(9) COMP VALUE 0.
       01  WS-RSP-PTR               PIC S9(9) COMP VALUE 1.

       01  WS-REQUEST-TYPE          PIC X(6) VALUE SPACES.
       01  WS-USER-ID               PIC X(32) VALUE SPACES.
       01  WS-BOOK-ID               PIC X(32) VALUE SPACES.
       01  WS-LOAN-ID               PIC X(32) VALUE SPACES.
       01  WS-STATUS-CODE           PIC X(4)  VALUE 'OK'.
       01  WS-STATUS-MESSAGE        PIC X(80) VALUE SPACES.

       01  WS-ACTIVE-COUNT          PIC S9(9) COMP VALUE 0.
       01  WS-RETURN-COUNT          PIC S9(9) COMP VALUE 0.
       01  WS-START                 PIC S9(9) COMP VALUE 0.
       01  WS-END                   PIC S9(9) COMP VALUE 0.
       01  WS-LEN                   PIC S9(9) COMP VALUE 0.

       01  WS-TAG-USER-START        PIC X(10) VALUE '<user><id>'.
       01  WS-TAG-USER-END          PIC X(12) VALUE '</id></user>'.
       01  WS-TAG-BOOK-START        PIC X(10) VALUE '<book><id>'.
       01  WS-TAG-BOOK-END          PIC X(12) VALUE '</id></book>'.
       01  WS-TAG-ACTIVE-USER-START PIC X(8)  VALUE '<userId>'.
       01  WS-TAG-ACTIVE-USER-END   PIC X(9)  VALUE '</userId>'.
       01  WS-TAG-LOANID-START      PIC X(8)  VALUE '<loanId>'.
       01  WS-TAG-LOANID-END        PIC X(9)  VALUE '</loanId>'.

       PROCEDURE DIVISION.

       MAIN-SECTION.
           MOVE 'STEP1 START' TO WS-TERM-MSG
           PERFORM SEND-TEXT.

           CALL 'MQCONN' USING WS-QMGR-NAME
                               HCONN
                               COMPCODE
                               REASON
           IF COMPCODE NOT = MQCC-OK
              MOVE 'MQCONN FAIL' TO WS-TERM-MSG
              PERFORM SHOW-MQ-RESULT
              GO TO PROGRAM-END
           END-IF

           MOVE MQOD-VERSION-4 TO MQOD-VERSION
           MOVE SPACES         TO MQOD-OBJECTNAME
           MOVE WS-REQ-QUEUE   TO MQOD-OBJECTNAME
           CALL 'MQOPEN' USING HCONN
                               MQM-OBJECT-DESCRIPTOR
                               MQOO-INPUT-SHARED
                               HOBJ-REQ
                               COMPCODE
                               REASON
           IF COMPCODE NOT = MQCC-OK
              MOVE 'MQOPEN REQ FAIL' TO WS-TERM-MSG
              PERFORM SHOW-MQ-RESULT
              GO TO MQ-DISCONNECT
           END-IF

           MOVE MQOD-VERSION-4 TO MQOD-VERSION
           MOVE SPACES         TO MQOD-OBJECTNAME
           MOVE WS-RPLY-QUEUE  TO MQOD-OBJECTNAME
           CALL 'MQOPEN' USING HCONN
                               MQM-OBJECT-DESCRIPTOR
                               MQOO-OUTPUT
                               HOBJ-RPLY
                               COMPCODE
                               REASON
           IF COMPCODE NOT = MQCC-OK
              MOVE 'MQOPEN RPLY FAIL' TO WS-TERM-MSG
              PERFORM SHOW-MQ-RESULT
              GO TO MQ-CLOSE-REQ
           END-IF

           MOVE MQMD-VERSION-2             TO MQMD-VERSION
           MOVE MQMT-REQUEST               TO MQMD-MSGTYPE
           MOVE MQFMT-STRING               TO MQMD-FORMAT
           MOVE MQENC-NATIVE               TO MQMD-ENCODING
           MOVE 1047                       TO MQMD-CODEDCHARSETID

           MOVE MQGMO-VERSION-1            TO MQGMO-VERSION
           MOVE MQGMO-WAIT                 TO MQGMO-OPTIONS
           ADD  MQGMO-CONVERT              TO MQGMO-OPTIONS
           ADD  MQGMO-FAIL-IF-QUIESCING    TO MQGMO-OPTIONS
           ADD  MQGMO-SYNCPOINT            TO MQGMO-OPTIONS
           MOVE WS-WAIT-MS                 TO MQGMO-WAITINTERVAL

           MOVE SPACES TO REQ-DATA
           MOVE 0      TO REQ-DATA-LEN
           CALL 'MQGET' USING HCONN
                             HOBJ-REQ
                             MQM-MESSAGE-DESCRIPTOR
                             MQM-GET-MESSAGE-OPTIONS
                             REQ-BUF-LEN
                             REQ-DATA
                             REQ-DATA-LEN
                             COMPCODE
                             REASON
           IF COMPCODE NOT = MQCC-OK
              IF REASON = MQRC-NO-MSG-AVAILABLE
                 MOVE WS-WAIT-MS TO WS-WAIT-DISP
                 STRING 'MQGET NO MSG WAIT=' DELIMITED BY SIZE
                        WS-WAIT-DISP         DELIMITED BY SIZE
                   INTO WS-TERM-MSG
                 END-STRING
                 PERFORM SEND-TEXT
                 GO TO MQ-CLOSE-BOTH
              END-IF
              MOVE 'MQGET FAIL' TO WS-TERM-MSG
              PERFORM SHOW-MQ-RESULT
              GO TO MQ-CLOSE-BOTH
           END-IF

           MOVE REQ-DATA-LEN TO WS-DATA-LEN-DISP
           STRING 'MQGET OK LEN=' DELIMITED BY SIZE
                  WS-DATA-LEN-DISP DELIMITED BY SIZE
             INTO WS-TERM-MSG
           END-STRING
           PERFORM SEND-TEXT

           PERFORM PARSE-REQUEST
           PERFORM BUILD-STUB-RESPONSE

           MOVE MQMD-MSGID TO MQMD-CORRELID
           MOVE MQMI-NONE  TO MQMD-MSGID
           MOVE MQMT-REPLY TO MQMD-MSGTYPE
           MOVE MQFMT-STRING TO MQMD-FORMAT
           MOVE MQENC-NATIVE TO MQMD-ENCODING
           MOVE 1047         TO MQMD-CODEDCHARSETID

           MOVE MQPMO-VERSION-1         TO MQPMO-VERSION
           MOVE MQPMO-NO-SYNCPOINT      TO MQPMO-OPTIONS
           ADD  MQPMO-SYNCPOINT         TO MQPMO-OPTIONS
           ADD  MQPMO-FAIL-IF-QUIESCING TO MQPMO-OPTIONS

           CALL 'MQPUT' USING HCONN
                             HOBJ-RPLY
                             MQM-MESSAGE-DESCRIPTOR
                             MQM-PUT-MESSAGE-OPTIONS
                             RSP-DATA-LEN
                             RSP-DATA
                             COMPCODE
                             REASON
           IF COMPCODE NOT = MQCC-OK
              MOVE 'MQPUT FAIL' TO WS-TERM-MSG
              PERFORM SHOW-MQ-RESULT
              EXEC CICS SYNCPOINT ROLLBACK END-EXEC
              GO TO MQ-CLOSE-BOTH
           END-IF

           EXEC CICS SYNCPOINT END-EXEC
           MOVE 'MQPUT OK' TO WS-TERM-MSG
           PERFORM SHOW-MQ-RESULT
           MOVE 'REPLY SENT WITH CORRELID=REQ MSGID' TO WS-TERM-MSG
           PERFORM SEND-TEXT

       MQ-CLOSE-BOTH.
           IF HOBJ-RPLY NOT = 0
              CALL 'MQCLOSE' USING HCONN
                                  HOBJ-RPLY
                                  MQCO-NONE
                                  COMPCODE
                                  REASON
           END-IF.

       MQ-CLOSE-REQ.
           IF HOBJ-REQ NOT = 0
              CALL 'MQCLOSE' USING HCONN
                                  HOBJ-REQ
                                  MQCO-NONE
                                  COMPCODE
                                  REASON
           END-IF.

       MQ-DISCONNECT.
           IF HCONN NOT = 0
              CALL 'MQDISC' USING HCONN
                                  COMPCODE
                                  REASON
           END-IF.

       PROGRAM-END.
           MOVE 0 TO WS-RESP WS-RESP2
           EXEC CICS RETURN
                RESP(WS-RESP)
                RESP2(WS-RESP2)
           END-EXEC
           GOBACK.

       SEND-TEXT.
           MOVE 0 TO WS-RESP WS-RESP2
           EXEC CICS SEND TEXT
                FROM(WS-TERM-MSG)
                LENGTH(40)
                ERASE
                RESP(WS-RESP)
                RESP2(WS-RESP2)
           END-EXEC
           EXIT.

       SHOW-MQ-RESULT.
           MOVE COMPCODE TO WS-COMPCODE-DISP
           MOVE REASON   TO WS-REASON-DISP
           STRING WS-TERM-MSG        DELIMITED BY SIZE
                  ' CC='             DELIMITED BY SIZE
                  WS-COMPCODE-DISP   DELIMITED BY SIZE
                  ' RC='             DELIMITED BY SIZE
                  WS-REASON-DISP     DELIMITED BY SIZE
             INTO WS-TERM-MSG2
           END-STRING
           MOVE WS-TERM-MSG2 TO WS-TERM-MSG
           PERFORM SEND-TEXT
           EXIT.

       PARSE-REQUEST.
           MOVE SPACES TO WS-REQUEST-TYPE WS-USER-ID WS-BOOK-ID WS-LOAN-ID
           MOVE 'OK'   TO WS-STATUS-CODE
           MOVE SPACES TO WS-STATUS-MESSAGE

           MOVE 0 TO WS-ACTIVE-COUNT
           INSPECT REQ-DATA
               TALLYING WS-ACTIVE-COUNT
               FOR ALL '<HostActiveLoansByUserRequest'

           MOVE 0 TO WS-RETURN-COUNT
           INSPECT REQ-DATA
               TALLYING WS-RETURN-COUNT
               FOR ALL '<HostReturnRequest'

           IF WS-ACTIVE-COUNT > 0
              MOVE 'ACTIVE' TO WS-REQUEST-TYPE
              PERFORM EXTRACT-ACTIVE-USER-ID
              IF WS-USER-ID = SPACES
                 MOVE 'ERR ' TO WS-STATUS-CODE
                 MOVE 'Invalid ACTIVE request' TO WS-STATUS-MESSAGE
              END-IF
           ELSE
              IF WS-RETURN-COUNT > 0
                 MOVE 'RETURN' TO WS-REQUEST-TYPE
                 PERFORM EXTRACT-LOAN-ID
                 IF WS-LOAN-ID = SPACES
                    MOVE 'ERR ' TO WS-STATUS-CODE
                    MOVE 'Invalid RETURN request' TO WS-STATUS-MESSAGE
                 END-IF
              ELSE
                 MOVE 'BORROW' TO WS-REQUEST-TYPE
                 PERFORM EXTRACT-USER
                 PERFORM EXTRACT-BOOK
                 IF WS-USER-ID = SPACES OR WS-BOOK-ID = SPACES
                    MOVE 'ERR ' TO WS-STATUS-CODE
                    MOVE 'Invalid BORROW request' TO WS-STATUS-MESSAGE
                 END-IF
              END-IF
           END-IF.

       EXTRACT-USER.
           MOVE 0 TO WS-START WS-END WS-LEN
           INSPECT REQ-DATA
               TALLYING WS-START
               FOR CHARACTERS BEFORE WS-TAG-USER-START
           IF WS-START >= LENGTH OF REQ-DATA
              EXIT PARAGRAPH
           END-IF
           COMPUTE WS-START = WS-START + LENGTH OF WS-TAG-USER-START
           INSPECT REQ-DATA
               TALLYING WS-END
               FOR CHARACTERS BEFORE WS-TAG-USER-END
           IF WS-END <= WS-START
              EXIT PARAGRAPH
           END-IF
           COMPUTE WS-LEN = WS-END - WS-START
           IF WS-LEN > 0
              MOVE REQ-DATA (WS-START + 1: WS-LEN) TO WS-USER-ID
           END-IF.

       EXTRACT-BOOK.
           MOVE 0 TO WS-START WS-END WS-LEN
           INSPECT REQ-DATA
               TALLYING WS-START
               FOR CHARACTERS BEFORE WS-TAG-BOOK-START
           IF WS-START >= LENGTH OF REQ-DATA
              EXIT PARAGRAPH
           END-IF
           COMPUTE WS-START = WS-START + LENGTH OF WS-TAG-BOOK-START
           INSPECT REQ-DATA
               TALLYING WS-END
               FOR CHARACTERS BEFORE WS-TAG-BOOK-END
           IF WS-END <= WS-START
              EXIT PARAGRAPH
           END-IF
           COMPUTE WS-LEN = WS-END - WS-START
           IF WS-LEN > 0
              MOVE REQ-DATA (WS-START + 1: WS-LEN) TO WS-BOOK-ID
           END-IF.

       EXTRACT-ACTIVE-USER-ID.
           MOVE 0 TO WS-START WS-END WS-LEN
           INSPECT REQ-DATA
               TALLYING WS-START
               FOR CHARACTERS BEFORE WS-TAG-ACTIVE-USER-START
           IF WS-START >= LENGTH OF REQ-DATA
              EXIT PARAGRAPH
           END-IF
           COMPUTE WS-START = WS-START + LENGTH OF WS-TAG-ACTIVE-USER-START
           INSPECT REQ-DATA
               TALLYING WS-END
               FOR CHARACTERS BEFORE WS-TAG-ACTIVE-USER-END
           IF WS-END <= WS-START
              EXIT PARAGRAPH
           END-IF
           COMPUTE WS-LEN = WS-END - WS-START
           IF WS-LEN > 0
              MOVE REQ-DATA (WS-START + 1: WS-LEN) TO WS-USER-ID
           END-IF.

       EXTRACT-LOAN-ID.
           MOVE 0 TO WS-START WS-END WS-LEN
           INSPECT REQ-DATA
               TALLYING WS-START
               FOR CHARACTERS BEFORE WS-TAG-LOANID-START
           IF WS-START >= LENGTH OF REQ-DATA
              EXIT PARAGRAPH
           END-IF
           COMPUTE WS-START = WS-START + LENGTH OF WS-TAG-LOANID-START
           INSPECT REQ-DATA
               TALLYING WS-END
               FOR CHARACTERS BEFORE WS-TAG-LOANID-END
           IF WS-END <= WS-START
              EXIT PARAGRAPH
           END-IF
           COMPUTE WS-LEN = WS-END - WS-START
           IF WS-LEN > 0
              MOVE REQ-DATA (WS-START + 1: WS-LEN) TO WS-LOAN-ID
           END-IF.

       BUILD-STUB-RESPONSE.
           MOVE SPACES TO RSP-DATA
           MOVE 1      TO WS-RSP-PTR

           IF WS-REQUEST-TYPE = 'ACTIVE'
              IF WS-STATUS-CODE = 'OK'
                 MOVE 'Active loans stub without DB2' TO WS-STATUS-MESSAGE
              END-IF
              STRING
                 '<HostActiveLoansByUserResponse xmlns="http://company'
                 '.com/library/host/schema">' DELIMITED BY SIZE
                 '<statusCode>'               DELIMITED BY SIZE
                 FUNCTION TRIM(WS-STATUS-CODE) DELIMITED BY SIZE
                 '</statusCode>'              DELIMITED BY SIZE
                 '<message>'                  DELIMITED BY SIZE
                 FUNCTION TRIM(WS-STATUS-MESSAGE) DELIMITED BY SIZE
                 '</message>'                 DELIMITED BY SIZE
                 '<userId>'                   DELIMITED BY SIZE
                 FUNCTION TRIM(WS-USER-ID)    DELIMITED BY SIZE
                 '</userId>'                  DELIMITED BY SIZE
                 '</HostActiveLoansByUserResponse>' DELIMITED BY SIZE
                 INTO RSP-DATA WITH POINTER WS-RSP-PTR
              END-STRING
           ELSE
              IF WS-REQUEST-TYPE = 'RETURN'
                 IF WS-STATUS-CODE = 'OK'
                    MOVE 'Return stub accepted without DB2' TO WS-STATUS-MESSAGE
                 END-IF
                 STRING
                    '<HostReturnResponse xmlns="http://company.com/libra'
                    'ry/host/schema">'         DELIMITED BY SIZE
                    '<loan><loanId>'           DELIMITED BY SIZE
                    FUNCTION TRIM(WS-LOAN-ID)  DELIMITED BY SIZE
                    '</loanId></loan>'         DELIMITED BY SIZE
                    '<statusCode>'             DELIMITED BY SIZE
                    FUNCTION TRIM(WS-STATUS-CODE) DELIMITED BY SIZE
                    '</statusCode>'            DELIMITED BY SIZE
                    '<message>'                DELIMITED BY SIZE
                    FUNCTION TRIM(WS-STATUS-MESSAGE) DELIMITED BY SIZE
                    '</message>'               DELIMITED BY SIZE
                    '</HostReturnResponse>'    DELIMITED BY SIZE
                    INTO RSP-DATA WITH POINTER WS-RSP-PTR
                 END-STRING
              ELSE
                 IF WS-STATUS-CODE = 'OK'
                    MOVE 'Borrow stub accepted without DB2' TO WS-STATUS-MESSAGE
                 END-IF
                 STRING
                    '<HostBorrowResponse xmlns="http://company.com/libra'
                    'ry/host/schema">'         DELIMITED BY SIZE
                    '<loan><user><id>'         DELIMITED BY SIZE
                    FUNCTION TRIM(WS-USER-ID)  DELIMITED BY SIZE
                    '</id></user><book><id>'   DELIMITED BY SIZE
                    FUNCTION TRIM(WS-BOOK-ID)  DELIMITED BY SIZE
                    '</id></book></loan>'      DELIMITED BY SIZE
                    '<statusCode>'             DELIMITED BY SIZE
                    FUNCTION TRIM(WS-STATUS-CODE) DELIMITED BY SIZE
                    '</statusCode>'            DELIMITED BY SIZE
                    '<message>'                DELIMITED BY SIZE
                    FUNCTION TRIM(WS-STATUS-MESSAGE) DELIMITED BY SIZE
                    '</message>'               DELIMITED BY SIZE
                    '</HostBorrowResponse>'    DELIMITED BY SIZE
                    INTO RSP-DATA WITH POINTER WS-RSP-PTR
                 END-STRING
              END-IF
           END-IF

           COMPUTE RSP-DATA-LEN = WS-RSP-PTR - 1.

       END PROGRAM LIBMQCIC.
