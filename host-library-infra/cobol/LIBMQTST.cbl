CBL NOXREF NOMAP NOOFFSET NOSOURCE
       IDENTIFICATION DIVISION.
       PROGRAM-ID. LIBMQTST.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT PARAMSFILE ASSIGN TO PARAMS
               ORGANIZATION IS SEQUENTIAL
               ACCESS IS SEQUENTIAL
               FILE STATUS IS PARAMS-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  PARAMSFILE
           RECORDING MODE IS F
           RECORD CONTAINS 80 CHARACTERS.
       01  PARAMS-REC               PIC X(80).

       WORKING-STORAGE SECTION.

       EXEC SQL INCLUDE SQLCA END-EXEC.

       01  PARAMS-STATUS            PIC XX.
       01  WS-SQLCODE-EDIT      PIC -ZZZ,ZZZ,ZZ9 USAGE DISPLAY.

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

       01  WS-QMGR-NAME       PIC X(48) VALUE SPACES.
       01  WS-REQ-QUEUE       PIC X(48) VALUE SPACES.
       01  WS-REP-QUEUE       PIC X(48) VALUE SPACES.
       01  WS-WAIT-MS-DISP    PIC 9(9)   VALUE 0.
       01  WS-WAIT-VAL-STR    PIC X(9).
       01  WS-WAIT-LEN        PIC S9(4) COMP.
       01  WS-WAIT-MS         PIC S9(9) COMP-5 VALUE 0.
       01  WS-CTL-LINE        PIC X(256).
       01  WS-VAL             PIC X(200).
       01  WS-EOF             PIC X VALUE 'N'.
       01  WS-KEY             PIC X(16).
       01  WS-REQUEST-TYPE    PIC X(6) VALUE SPACES.

           COPY LIBLOAN.

       01  HCONN        PIC S9(9) COMP.
       01  HOBJ-REQ     PIC S9(9) COMP.
       01  HOBJ-REP     PIC S9(9) COMP.
       01  COMPCODE     PIC S9(9) COMP.
       01  REASON       PIC S9(9) COMP.

       01  REQ-DATA             PIC X(8192).
       01  RSP-DATA             PIC X(256).
       01  REQ-DATA-LEN         PIC S9(9) COMP VALUE 8192.
       01  RSP-DATA-LEN         PIC S9(9) COMP VALUE 0.

       01  WS-ACTIVE-COUNT      PIC S9(9) COMP VALUE 0.
       01  WS-LOAN-ID-NUM       PIC S9(9) COMP VALUE 0.
       01  WS-NEW-LOAN-NUM      PIC 9(9)    VALUE 0.
       01  WS-NEW-LOAN-ID       PIC X(10)   VALUE SPACES.
       01  WS-PADDED            PIC X(9)    VALUE SPACES.

       01  WS-SQL-MSG           PIC X(80)   VALUE SPACES.
       01  WS-XML-REQUEST       PIC X(8192) VALUE SPACES.
       01  WS-XML-RESPONSE      PIC X(8192) VALUE SPACES.
       01  WS-XML               PIC X(8192) VALUE SPACES.
       01  WS-XML-LEN           PIC S9(9) COMP.
       01  WS-PTR               PIC S9(9) COMP.

       01  WS-RETURN-COUNT      PIC S9(9) COMP VALUE 0.
       01  WS-TAG-USER-START    PIC X(10)    VALUE "<user><id>".
       01  WS-TAG-USER-END      PIC X(12)    VALUE "</id></user>".
       01  WS-TAG-BOOK-START    PIC X(10)    VALUE "<book><id>".
       01  WS-TAG-BOOK-END      PIC X(12)    VALUE "</id></book>".
       01  WS-TAG-LOANID-START  PIC X(8)     VALUE "<loanId>".
       01  WS-TAG-LOANID-END    PIC X(9)     VALUE "</loanId>".
       01  WS-START             PIC S9(9) COMP VALUE 0.
       01  WS-END               PIC S9(9) COMP VALUE 0.
       01  WS-LEN               PIC S9(9) COMP VALUE 0.
      *
      *    W03 - MQ API fields
      *
       01  W03-BUFFER-LENGTH           PIC S9(9) BINARY  VALUE 80.
       01  W03-HCONN                   PIC S9(9) COMP-5.
       01  W03-OPTIONS                 PIC S9(9) BINARY.
       01  W03-HOBJ                    PIC S9(9) BINARY.
       01  W03-DATA-LENGTH             PIC S9(9) BINARY.
       01  W03-COMPCODE                PIC S9(9) BINARY.
       01  W03-REASON                  PIC S9(9) BINARY.
       01  W03-MESSAGE-DATA            PIC X(80) VALUE SPACES.

       PROCEDURE DIVISION.

       MAIN-SECTION.

           DISPLAY 'LIBMQTST STARTING'.

           PERFORM READ-CONFIG
           PERFORM VALIDATE-CONFIG

           IF WS-QMGR-NAME = SPACES OR WS-REQ-QUEUE = SPACES
               DISPLAY 'MISSING SYSIN: QMGR OR REQUEST QUEUE'
               GOBACK
           END-IF
           DISPLAY 'MQ QMGR=' WS-QMGR-NAME
                   ' REQQ=' WS-REQ-QUEUE
                   ' RPLYQ=' WS-REP-QUEUE
                   ' WAIT_MS=' WS-WAIT-MS.

           CALL 'MQCONN' USING WS-QMGR-NAME
                               HCONN
                               COMPCODE
                               REASON.
           IF COMPCODE NOT = MQCC-OK
               DISPLAY 'MQCONN FAILED, REASON=' REASON
               GOBACK
           END-IF.
           DISPLAY 'MQCONN SUCCEEDED, HCONN=' HCONN.

           MOVE MQOD-VERSION-4 TO MQOD-VERSION.
           MOVE WS-REQ-QUEUE    TO MQOD-OBJECTNAME.
           CALL 'MQOPEN' USING HCONN
                               MQM-OBJECT-DESCRIPTOR
                               MQOO-INPUT-SHARED
                               HOBJ-REQ
                               COMPCODE
                               REASON.
           IF COMPCODE NOT = MQCC-OK
               DISPLAY 'MQOPEN REQ FAILED, REASON=' REASON
               GO TO MQ-DISCONNECT
           END-IF.

           MOVE MQOD-VERSION-4 TO MQOD-VERSION.
           MOVE WS-REP-QUEUE    TO MQOD-OBJECTNAME.
           CALL 'MQOPEN' USING HCONN
                               MQM-OBJECT-DESCRIPTOR
                               MQOO-OUTPUT
                               HOBJ-REP
                               COMPCODE
                               REASON.
           IF COMPCODE NOT = MQCC-OK
               DISPLAY 'MQOPEN REP FAILED, REASON=' REASON
               GO TO MQ-CLOSE-REQ
           END-IF.
           DISPLAY 'MQOPEN SUCCEEDED FOR BOTH QUEUES'.

           MOVE MQGMO-VERSION-1         TO MQGMO-VERSION.
           MOVE MQMT-DATAGRAM           TO MQMD-MSGTYPE.

           MOVE MQGMO-WAIT              TO MQGMO-OPTIONS
           ADD  MQGMO-CONVERT           TO MQGMO-OPTIONS
           ADD  MQGMO-FAIL-IF-QUIESCING TO MQGMO-OPTIONS
           MOVE WS-WAIT-MS              TO MQGMO-WAITINTERVAL.

           MOVE 1047                    TO MQMD-CODEDCHARSETID
           MOVE MQENC-NATIVE            TO MQMD-ENCODING.

           CALL 'MQGET' USING HCONN
                             HOBJ-REQ
                             MQM-MESSAGE-DESCRIPTOR
                             MQM-GET-MESSAGE-OPTIONS
                             REQ-DATA-LEN
                             REQ-DATA
                             W03-DATA-LENGTH
                             COMPCODE
                             REASON.
           IF COMPCODE NOT = MQCC-OK
              DISPLAY 'MQGET failed CC=' COMPCODE
                      ' RC=' REASON
              DISPLAY 'MQMD-FORMAT =' MQMD-FORMAT
              DISPLAY 'MQMD-CODEDCHARSETID =' MQMD-CODEDCHARSETID
              DISPLAY 'MQMD-ENCODING =' MQMD-ENCODING
              GO TO MQ-CLOSE-BOTH
           ELSE
              DISPLAY 'Got ' W03-DATA-LENGTH
                ' bytes (converted to CCSID '
                      MQMD-CODEDCHARSETID ')'
              DISPLAY 'MSG: '  REQ-DATA(1:W03-DATA-LENGTH)
           END-IF.

           MOVE MQMD-MSGID      TO MQMD-CORRELID.
           MOVE MQMI-NONE       TO MQMD-MSGID.

           MOVE REQ-DATA(1:W03-DATA-LENGTH) TO WS-XML-REQUEST.

           PERFORM PARSE-XML-REQUEST.

           IF WS-REQUEST-TYPE = 'RETURN'
               DISPLAY 'PARSE COMPLETE, STATUS=' HRR-STATUS-CODE
           ELSE
               DISPLAY 'PARSE COMPLETE, STATUS=' HBR-STATUS-CODE
           END-IF

           IF WS-REQUEST-TYPE = 'RETURN'
               IF HRR-STATUS-CODE NOT = 'ERR '
                   PERFORM PROCESS-RETURN
               END-IF
           ELSE
               IF HBR-STATUS-CODE NOT = 'ERR '
                   PERFORM PROCESS-BORROW
               END-IF
           END-IF

           IF WS-REQUEST-TYPE = 'RETURN'
               DISPLAY 'PROCESS COMPLETE, STATUS=' HRR-STATUS-CODE
           ELSE
               DISPLAY 'PROCESS COMPLETE, STATUS=' HBR-STATUS-CODE
           END-IF

           PERFORM BUILD-XML-RESPONSE.

           MOVE MQPMO-VERSION-1 TO MQPMO-VERSION.
           MOVE MQPMO-NO-SYNCPOINT TO MQPMO-OPTIONS.

           COMPUTE RSP-DATA-LEN = FUNCTION LENGTH(RSP-DATA).

           CALL 'MQPUT' USING HCONN
                             HOBJ-REP
                             MQM-MESSAGE-DESCRIPTOR
                             MQM-PUT-MESSAGE-OPTIONS
                             RSP-DATA-LEN
                             RSP-DATA
                             COMPCODE
                             REASON.
           IF COMPCODE NOT = MQCC-OK
               DISPLAY 'MQPUT FAILED, REASON=' REASON
           ELSE
               DISPLAY 'REPLY SENT, CORRELID SET FROM REQUEST MSGID'
           END-IF.

       MQ-CLOSE-BOTH.
           CALL 'MQCLOSE' USING HCONN
                               HOBJ-REP
                               MQCO-NONE
                               COMPCODE
                               REASON.
       MQ-CLOSE-REQ.
           CALL 'MQCLOSE' USING HCONN
                               HOBJ-REQ
                               MQCO-NONE
                               COMPCODE
                               REASON.
       MQ-DISCONNECT.
           CALL 'MQDISC' USING HCONN
                               COMPCODE
                               REASON.

           DISPLAY 'LIBMQTST ENDING'.
           GOBACK.

      ******************************************************************
      ** Process the request using DB2 and build response
      ******************************************************************
       PROCESS-BORROW.
           MOVE SPACES TO HOST-BORROW-RESPONSE.
           MOVE HBR-USER-ID        TO HBR-USER-ID-R.
           MOVE HBR-BOOK-ID        TO HBR-BOOK-ID-R.

           EXEC SQL
              SELECT COUNT(*)
                INTO :WS-ACTIVE-COUNT
                FROM LOAN
               WHERE BOOK_ID    = :HBR-BOOK-ID
                 AND RETURN_DATE IS NULL
           END-EXEC

           DISPLAY 'sqlcode after select= ' SQLCODE
           DISPLAY 'ACTIVE COUNT=' WS-ACTIVE-COUNT

           IF SQLCODE NOT = 0
               PERFORM SQL-ERROR
               PERFORM BUILD-RESPONSE
                EXIT
           END-IF

           IF WS-ACTIVE-COUNT > 0
               MOVE 'BUSY' TO HBR-STATUS-CODE
               MOVE 'Book already on loan' TO HBR-MESSAGE
               DISPLAY 'BOOK ' HBR-BOOK-ID ' ALREADY ON LOAN'
               PERFORM BUILD-RESPONSE
                EXIT
           END-IF

           EXEC SQL
              INSERT INTO LOAN
                   (USER_ID, BOOK_ID, LOAN_DATE, DUE_DATE, RETURN_DATE)
              VALUES (:HBR-USER-ID, :HBR-BOOK-ID,
                      CURRENT DATE, CURRENT DATE + 14 DAYS, NULL)
           END-EXEC

           DISPLAY 'sqlcode after insert= ' SQLCODE

           IF SQLCODE NOT = 0
               PERFORM SQL-ERROR
               PERFORM BUILD-RESPONSE
               EXIT
           END-IF

           EXEC SQL
              VALUES IDENTITY_VAL_LOCAL()
                INTO :WS-LOAN-ID-NUM
           END-EXEC

           DISPLAY 'sqlcode after IDENTITY_VAL_LOCAL= ' SQLCODE
           IF SQLCODE NOT = 0
               PERFORM SQL-ERROR
               PERFORM BUILD-RESPONSE
               EXIT
           END-IF

           MOVE WS-LOAN-ID-NUM TO WS-NEW-LOAN-NUM
           DISPLAY 'NEW LOAN NUM=' WS-NEW-LOAN-NUM

           MOVE SPACES TO WS-NEW-LOAN-ID
           MOVE 'L'    TO WS-NEW-LOAN-ID (1:1)
           MOVE WS-NEW-LOAN-NUM TO WS-NEW-LOAN-ID (2:9)

           DISPLAY 'WS-NEW-LOAN-ID=' WS-NEW-LOAN-ID

           MOVE WS-NEW-LOAN-ID TO HBR-LOAN-ID
           MOVE 'OK'           TO HBR-STATUS-CODE
           MOVE 'Loan created' TO HBR-MESSAGE
           DISPLAY 'LOAN CREATED, ID=' HBR-LOAN-ID

           EXEC SQL COMMIT END-EXEC.

       PROCESS-RETURN.
           MOVE SPACES TO HOST-RETURN-RESPONSE.
           MOVE HRR-LOAN-ID TO HRR-LOAN-ID-R.
           MOVE SPACES TO HRR-USER-ID-R HRR-BOOK-ID-R.

           IF HRR-LOAN-ID = SPACES
               MOVE 'ERR ' TO HRR-STATUS-CODE
               MOVE 'Missing loanId' TO HRR-MESSAGE
               EXIT
           END-IF

           MOVE SPACES TO WS-PADDED
           IF HRR-LOAN-ID(1:1) = 'L'
               MOVE HRR-LOAN-ID(2:9) TO WS-PADDED
           ELSE
               MOVE HRR-LOAN-ID TO WS-PADDED
           END-IF

           IF WS-PADDED IS NOT NUMERIC
               MOVE 'ERR ' TO HRR-STATUS-CODE
               MOVE 'Invalid loanId' TO HRR-MESSAGE
               EXIT
           END-IF

           MOVE WS-PADDED TO WS-LOAN-ID-NUM

           EXEC SQL
              SELECT USER_ID, BOOK_ID
                INTO :HRR-USER-ID-R, :HRR-BOOK-ID-R
                FROM LOAN
               WHERE LOAN_ID_NUM = :WS-LOAN-ID-NUM
                 AND RETURN_DATE IS NULL
           END-EXEC

           DISPLAY 'sqlcode after select= ' SQLCODE

           IF SQLCODE = 100
               MOVE 'NOTF' TO HRR-STATUS-CODE
               MOVE 'Loan not found or already returned' TO HRR-MESSAGE
               EXIT
           END-IF

           IF SQLCODE NOT = 0
               PERFORM SQL-ERROR
               EXIT
           END-IF

           EXEC SQL
              UPDATE LOAN
                 SET RETURN_DATE = CURRENT DATE
               WHERE LOAN_ID_NUM = :WS-LOAN-ID-NUM
                 AND RETURN_DATE IS NULL
           END-EXEC

           DISPLAY 'sqlcode after update= ' SQLCODE

           IF SQLCODE NOT = 0
               PERFORM SQL-ERROR
               EXIT
           END-IF

           MOVE 'OK' TO HRR-STATUS-CODE
           MOVE 'Loan returned' TO HRR-MESSAGE
           DISPLAY 'LOAN RETURNED, ID=' HRR-LOAN-ID-R

           EXEC SQL COMMIT END-EXEC.

       BUILD-RESPONSE.
           MOVE SPACES TO RSP-DATA.
           IF WS-REQUEST-TYPE = 'RETURN'
               MOVE HOST-RETURN-RESPONSE TO RSP-DATA
           ELSE
               MOVE HOST-BORROW-RESPONSE TO RSP-DATA
           END-IF.
           EXIT.

       SQL-ERROR.
           MOVE SPACES TO WS-SQL-MSG.
           MOVE SQLCODE TO WS-SQLCODE-EDIT.

           STRING 'SQL ERROR ' DELIMITED BY SIZE
               WS-SQLCODE-EDIT DELIMITED BY SIZE
             INTO WS-SQL-MSG.
           IF WS-REQUEST-TYPE = 'RETURN'
               MOVE 'ERR ' TO HRR-STATUS-CODE
               MOVE WS-SQL-MSG TO HRR-MESSAGE
           ELSE
               MOVE 'ERR ' TO HBR-STATUS-CODE
               MOVE WS-SQL-MSG TO HBR-MESSAGE
           END-IF.
           EXEC SQL ROLLBACK END-EXEC.
           EXIT.

      ******************************************************************
      ** Parse XML request into HOST-BORROW-REQUEST
      ******************************************************************
       PARSE-XML-REQUEST.
           MOVE SPACES TO HOST-BORROW-REQUEST HOST-RETURN-REQUEST.
           MOVE 'OK'    TO HBR-STATUS-CODE HRR-STATUS-CODE.
           MOVE SPACES  TO HBR-MESSAGE HRR-MESSAGE.
           MOVE SPACES  TO WS-REQUEST-TYPE.

           MOVE 0 TO WS-RETURN-COUNT.
           INSPECT WS-XML-REQUEST
               TALLYING WS-RETURN-COUNT
               FOR ALL "<HostReturnRequest".

           IF WS-RETURN-COUNT > 0
               MOVE 'RETURN' TO WS-REQUEST-TYPE
               PERFORM EXTRACT-LOAN-ID
               IF HRR-LOAN-ID = SPACES
                   MOVE 'ERR ' TO HRR-STATUS-CODE
                   MOVE 'Invalid XML' TO HRR-MESSAGE
               END-IF
           ELSE
               MOVE 'BORROW' TO WS-REQUEST-TYPE
               PERFORM EXTRACT-USER
               PERFORM EXTRACT-BOOK
               IF HBR-USER-ID = SPACES OR HBR-BOOK-ID = SPACES
                   MOVE 'ERR ' TO HBR-STATUS-CODE
                   MOVE 'Invalid XML' TO HBR-MESSAGE
               END-IF
           END-IF.

           EXIT.

       EXTRACT-USER.
           MOVE 0 TO WS-START WS-END WS-LEN.
           INSPECT WS-XML-REQUEST
               TALLYING WS-START
               FOR CHARACTERS BEFORE WS-TAG-USER-START.
           IF WS-START >= LENGTH OF WS-XML-REQUEST
               EXIT
           END-IF
           COMPUTE WS-START = WS-START + LENGTH OF WS-TAG-USER-START.
           INSPECT WS-XML-REQUEST
               TALLYING WS-END
               FOR CHARACTERS BEFORE WS-TAG-USER-END.
           IF WS-END <= WS-START
               EXIT
           END-IF
           COMPUTE WS-LEN = WS-END - WS-START.
           IF WS-LEN > 0
               MOVE WS-XML-REQUEST (WS-START + 1: WS-LEN) TO HBR-USER-ID
           END-IF
           DISPLAY 'EXTRACT-USER: ' HBR-USER-ID
           EXIT.

       EXTRACT-BOOK.
           MOVE 0 TO WS-START WS-END WS-LEN.
           INSPECT WS-XML-REQUEST
               TALLYING WS-START
               FOR CHARACTERS BEFORE WS-TAG-BOOK-START.
           IF WS-START >= LENGTH OF WS-XML-REQUEST
               EXIT
           END-IF
           COMPUTE WS-START = WS-START + LENGTH OF WS-TAG-BOOK-START.
           INSPECT WS-XML-REQUEST
               TALLYING WS-END
               FOR CHARACTERS BEFORE WS-TAG-BOOK-END.
           IF WS-END <= WS-START
               EXIT
           END-IF
           COMPUTE WS-LEN = WS-END - WS-START.
           IF WS-LEN > 0
               MOVE WS-XML-REQUEST (WS-START + 1: WS-LEN) TO HBR-BOOK-ID
           END-IF
           DISPLAY 'EXTRACT-BOOK: ' HBR-BOOK-ID
           EXIT.

       EXTRACT-LOAN-ID.
           MOVE 0 TO WS-START WS-END WS-LEN.
           INSPECT WS-XML-REQUEST
               TALLYING WS-START
               FOR CHARACTERS BEFORE WS-TAG-LOANID-START.
           IF WS-START >= LENGTH OF WS-XML-REQUEST
               EXIT
           END-IF
           COMPUTE WS-START = WS-START + LENGTH OF WS-TAG-LOANID-START.
           INSPECT WS-XML-REQUEST
               TALLYING WS-END
               FOR CHARACTERS BEFORE WS-TAG-LOANID-END.
           IF WS-END <= WS-START
               EXIT
           END-IF
           COMPUTE WS-LEN = WS-END - WS-START.
           IF WS-LEN > 0
               MOVE WS-XML-REQUEST (WS-START + 1: WS-LEN) TO HRR-LOAN-ID
           END-IF
           DISPLAY 'EXTRACT-LOAN-ID: ' HRR-LOAN-ID
           EXIT.

      ******************************************************************
      ** Build XML response from HOST-BORROW-RESPONSE
      ******************************************************************
       BUILD-XML-RESPONSE.
           MOVE SPACES TO WS-XML-RESPONSE.
           IF WS-REQUEST-TYPE = 'RETURN'
               STRING
                  '<HostReturnResponse ' DELIMITED BY SIZE
                  ' xmlns="http://company.com/library/host/schema">'
                                         DELIMITED BY SIZE
                  '<loan>'             DELIMITED BY SIZE
                  '<loanId>'             DELIMITED BY SIZE
                  HRR-LOAN-ID-R          DELIMITED BY SIZE
                  '</loanId>'            DELIMITED BY SIZE
                  '<user>'             DELIMITED BY SIZE
                  '<id>'             DELIMITED BY SIZE
                  HRR-USER-ID-R          DELIMITED BY SIZE
                  '</id>'             DELIMITED BY SIZE
                  '</user>'            DELIMITED BY SIZE
                  '<book>'             DELIMITED BY SIZE
                  '<id>'             DELIMITED BY SIZE
                  HRR-BOOK-ID-R          DELIMITED BY SIZE
                  '</id>'             DELIMITED BY SIZE
                  '</book>'            DELIMITED BY SIZE
                  '</loan>'             DELIMITED BY SIZE
                  '<statusCode>'         DELIMITED BY SIZE
                  FUNCTION TRIM(HRR-STATUS-CODE)   DELIMITED BY SIZE
                  '</statusCode>'        DELIMITED BY SIZE
                  '<message>'            DELIMITED BY SIZE
                  FUNCTION TRIM(HRR-MESSAGE) DELIMITED BY SIZE
                  '</message>'           DELIMITED BY SIZE
                  '</HostReturnResponse>' DELIMITED BY SIZE
                INTO WS-XML-RESPONSE
               END-STRING
           ELSE
               STRING
                  '<HostBorrowResponse ' DELIMITED BY SIZE
                  ' xmlns="http://company.com/library/host/schema">'
                                         DELIMITED BY SIZE
                  '<loan>'             DELIMITED BY SIZE
                  '<loanId>'             DELIMITED BY SIZE
                  HBR-LOAN-ID            DELIMITED BY SIZE
                  '</loanId>'            DELIMITED BY SIZE
                  '<user>'             DELIMITED BY SIZE
                  '<id>'             DELIMITED BY SIZE
                  HBR-USER-ID-R          DELIMITED BY SIZE
                  '</id>'             DELIMITED BY SIZE
                  '</user>'            DELIMITED BY SIZE
                  '<book>'             DELIMITED BY SIZE
                  '<id>'             DELIMITED BY SIZE
                  HBR-BOOK-ID-R          DELIMITED BY SIZE
                  '</id>'             DELIMITED BY SIZE
                  '</book>'            DELIMITED BY SIZE
                  '</loan>'             DELIMITED BY SIZE
                  '<statusCode>'         DELIMITED BY SIZE
                  FUNCTION TRIM(HBR-STATUS-CODE)   DELIMITED BY SIZE
                  '</statusCode>'        DELIMITED BY SIZE
                  '<message>'            DELIMITED BY SIZE
                  FUNCTION TRIM(HBR-MESSAGE) DELIMITED BY SIZE
                  '</message>'           DELIMITED BY SIZE
                  '</HostBorrowResponse>' DELIMITED BY SIZE
                INTO WS-XML-RESPONSE
               END-STRING
           END-IF.
           MOVE SPACES TO RSP-DATA.
           MOVE WS-XML-RESPONSE TO RSP-DATA.
           EXIT.

       READ-CONFIG.
           OPEN INPUT PARAMSFILE

           IF PARAMS-STATUS NOT = "00"
               DISPLAY "SYSIN OPEN FAILED, STATUS=" PARAMS-STATUS
               MOVE 12 TO RETURN-CODE
               GOBACK
           END-IF

           PERFORM UNTIL WS-EOF = 'Y'
               READ PARAMSFILE
                   AT END
                       MOVE 'Y' TO WS-EOF
                   NOT AT END
                       PERFORM PARSE-CTL-LINE
               END-READ
           END-PERFORM
           CLOSE PARAMSFILE.
           EXIT.

       PARSE-CTL-LINE.
           MOVE PARAMS-REC TO WS-CTL-LINE
           DISPLAY WS-CTL-LINE
           IF WS-CTL-LINE = SPACES
               EXIT PARAGRAPH
           END-IF
           IF WS-CTL-LINE(1:1) = '*'
               OR WS-CTL-LINE(1:1) = '#'
               EXIT PARAGRAPH
           END-IF

           MOVE SPACES TO WS-KEY
           MOVE SPACES TO WS-VAL

           UNSTRING WS-CTL-LINE
               DELIMITED BY '='
               INTO WS-KEY WS-VAL
           END-UNSTRING

           MOVE FUNCTION TRIM(WS-KEY) TO WS-KEY
           MOVE FUNCTION TRIM(WS-VAL) TO WS-VAL

           EVALUATE WS-KEY
               WHEN 'QMGR'
                   MOVE WS-VAL TO WS-QMGR-NAME
               WHEN 'REQ'
                   MOVE WS-VAL TO WS-REQ-QUEUE
               WHEN 'RPLY'
                   MOVE WS-VAL TO WS-REP-QUEUE
               WHEN 'WAIT_MS'
                   MOVE 0 TO WS-WAIT-MS-DISP
                   MOVE SPACES TO WS-WAIT-VAL-STR
                   MOVE FUNCTION TRIM(WS-VAL) TO WS-WAIT-VAL-STR
                   COMPUTE WS-WAIT-LEN =
                   FUNCTION LENGTH(FUNCTION TRIM(WS-VAL))

                   DISPLAY 'CONFIG : WAIT_MS_STR ' WS-WAIT-VAL-STR

                   IF WS-WAIT-LEN > 0
                      AND WS-WAIT-VAL-STR(1:WS-WAIT-LEN) IS NUMERIC
                      MOVE WS-WAIT-VAL-STR(1:WS-WAIT-LEN)
                        TO WS-WAIT-MS-DISP
                      COMPUTE WS-WAIT-MS = WS-WAIT-MS-DISP
                   ELSE
                      DISPLAY 'CONFIG ERROR: WAIT_MS not numeric'
                      MOVE 0 TO WS-WAIT-MS
                   END-IF
                   DISPLAY 'CONFIG : WS-VAL ' WS-VAL
                   DISPLAY 'CONFIG : WAIT_MS ' WS-WAIT-MS-DISP
               WHEN OTHER
                   CONTINUE
           END-EVALUATE.
           EXIT.

       VALIDATE-CONFIG.
           IF WS-QMGR-NAME = SPACES
               DISPLAY 'CONFIG ERROR: QMGR missing'
               MOVE 12 TO RETURN-CODE
               STOP RUN
           END-IF
           IF WS-REQ-QUEUE = SPACES
               DISPLAY 'CONFIG ERROR: REQ missing'
               MOVE 12 TO RETURN-CODE
               STOP RUN
           END-IF
           IF WS-REP-QUEUE = SPACES
               DISPLAY 'CONFIG ERROR: RPLY missing'
               MOVE 12 TO RETURN-CODE
               STOP RUN
           END-IF
           IF WS-WAIT-MS <= 0
               DISPLAY 'CONFIG ERROR: WAIT_MS invalid' WS-WAIT-MS-DISP
               MOVE 12 TO RETURN-CODE
               STOP RUN
           END-IF
           EXIT.

       END PROGRAM LIBMQTST.
