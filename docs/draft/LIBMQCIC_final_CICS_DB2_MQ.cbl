CBL SQL NOXREF NOMAP NOOFFSET NOSOURCE
       IDENTIFICATION DIVISION.
       PROGRAM-ID. LIBMQCIC.

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
       01  WS-SQLSTATE-DISP     PIC X(5).
       01  WS-SQLERRMC-DISP     PIC X(70).

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

       01  WS-QMGR-NAME       PIC X(48) VALUE 'CSQ9'.
       01  WS-REQ-QUEUE       PIC X(48)
           VALUE 'Z88011.MQZ3.QLOCAL'.
       01  WS-REP-QUEUE       PIC X(48)
           VALUE 'Z88011.MQZ3.REPLYTO.QLOCAL'.
       01  WS-WAIT-MS-DISP    PIC 9(9)   VALUE 30000.
       01  WS-WAIT-MS         PIC S9(9) COMP-5 VALUE 30000.
       01  WS-KEY             PIC X(16).
       01  WS-REQUEST-TYPE    PIC X(6) VALUE SPACES.

           COPY LIBLOAN.

           EXEC SQL
           DECLARE CUR-ACTIVE-LOANS CURSOR FOR
               SELECT LOAN_ID_NUM, BOOK_ID
                 FROM LOAN
                WHERE USER_ID = :HAU-USER-ID
                  AND RETURN_DATE IS NULL
                ORDER BY LOAN_ID_NUM
           END-EXEC.

       01  HCONN        PIC S9(9) COMP.
       01  HOBJ-REQ     PIC S9(9) COMP.
       01  HOBJ-REP     PIC S9(9) COMP.
       01  COMPCODE     PIC S9(9) COMP.
       01  REASON       PIC S9(9) COMP.

       01  REQ-DATA             PIC X(8192).
       01  RSP-DATA             PIC X(8192).
       01  REQ-DATA-LEN         PIC S9(9) COMP VALUE 8192.
       01  RSP-DATA-LEN         PIC S9(9) COMP VALUE 0.

       01  WS-ACTIVE-COUNT      PIC S9(9) COMP VALUE 0.
       01  WS-LOAN-ID-NUM       PIC S9(9) COMP VALUE 0.
       01  WS-NEW-LOAN-NUM      PIC 9(9)    VALUE 0.
       01  WS-NEW-LOAN-ID       PIC X(10)   VALUE SPACES.
       01  WS-PADDED            PIC X(9)    VALUE SPACES.
       01  WS-ACTIVE-LOAN-COUNT PIC 9(2)    COMP VALUE 0.
       01  WS-ACTIVE-LOAN-ID-NUM PIC S9(9) COMP VALUE 0.
       01  WS-ACTIVE-BOOK-ID    PIC X(10)   VALUE SPACES.

       01  WS-SQL-MSG           PIC X(80)   VALUE SPACES.
       01  WS-XML-REQUEST       PIC X(8192) VALUE SPACES.
       01  WS-XML-RESPONSE      PIC X(8192) VALUE SPACES.
       01  WS-XML               PIC X(8192) VALUE SPACES.
       01  WS-XML-LEN           PIC S9(9) COMP.
       01  WS-PTR               PIC S9(9) COMP.
       01  WS-INDEX             PIC 9(2) COMP VALUE 0.

       01  WS-RETURN-COUNT      PIC S9(9) COMP VALUE 0.
       01  WS-ACTIVE-REQ-COUNT  PIC S9(9) COMP VALUE 0.
       01  WS-TAG-USER-START    PIC X(10)    VALUE "<user><id>".
       01  WS-TAG-USER-END      PIC X(12)    VALUE "</id></user>".
       01  WS-TAG-BOOK-START    PIC X(10)    VALUE "<book><id>".
       01  WS-TAG-BOOK-END      PIC X(12)    VALUE "</id></book>".
       01  WS-TAG-ACTIVE-USERID-START PIC X(8) VALUE "<userId>".
       01  WS-TAG-ACTIVE-USERID-END   PIC X(9) VALUE "</userId>".
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

           DISPLAY 'LIBMQCIC STARTING'.

           CALL 'MQCONN' USING WS-QMGR-NAME
                               HCONN
                               COMPCODE
                               REASON.
           IF COMPCODE NOT = MQCC-OK
               DISPLAY 'MQCONN FAIL CC=' COMPCODE
               DISPLAY 'MQCONN FAIL RC=' REASON
               EXEC CICS RETURN END-EXEC
           END-IF.

           MOVE MQOD-VERSION-4 TO MQOD-VERSION.
           MOVE SPACES         TO MQOD-OBJECTNAME.
           MOVE WS-REQ-QUEUE   TO MQOD-OBJECTNAME.
           CALL 'MQOPEN' USING HCONN
                               MQM-OBJECT-DESCRIPTOR
                               MQOO-INPUT-SHARED
                               HOBJ-REQ
                               COMPCODE
                               REASON.
           IF COMPCODE NOT = MQCC-OK
               DISPLAY 'MQOPEN REQ FAIL CC=' COMPCODE
               DISPLAY 'MQOPEN REQ FAIL RC=' REASON
               GO TO MQ-DISCONNECT
           END-IF.

           MOVE MQOD-VERSION-4 TO MQOD-VERSION.
           MOVE SPACES         TO MQOD-OBJECTNAME.
           MOVE WS-REP-QUEUE   TO MQOD-OBJECTNAME.
           CALL 'MQOPEN' USING HCONN
                               MQM-OBJECT-DESCRIPTOR
                               MQOO-OUTPUT
                               HOBJ-REP
                               COMPCODE
                               REASON.
           IF COMPCODE NOT = MQCC-OK
               DISPLAY 'MQOPEN REP FAIL CC=' COMPCODE
               DISPLAY 'MQOPEN REP FAIL RC=' REASON
               GO TO MQ-CLOSE-REQ
           END-IF.

           MOVE MQMD-VERSION-2          TO MQMD-VERSION.
           MOVE MQMT-REQUEST            TO MQMD-MSGTYPE.
           MOVE MQFMT-STRING            TO MQMD-FORMAT.
           MOVE MQENC-NATIVE            TO MQMD-ENCODING.
           MOVE 1047                    TO MQMD-CODEDCHARSETID.

           MOVE MQGMO-VERSION-1         TO MQGMO-VERSION.
           MOVE MQGMO-WAIT              TO MQGMO-OPTIONS.
           ADD  MQGMO-CONVERT           TO MQGMO-OPTIONS.
           ADD  MQGMO-FAIL-IF-QUIESCING TO MQGMO-OPTIONS.
           ADD  MQGMO-SYNCPOINT         TO MQGMO-OPTIONS.
           MOVE WS-WAIT-MS              TO MQGMO-WAITINTERVAL.

           MOVE SPACES TO REQ-DATA.
           MOVE 0      TO W03-DATA-LENGTH.

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
              IF REASON = MQRC-NO-MSG-AVAILABLE
                  DISPLAY 'MQGET NO MSG WAIT=' WS-WAIT-MS-DISP
                  GO TO MQ-CLOSE-BOTH
              END-IF
              DISPLAY 'MQGET FAIL CC=' COMPCODE
              DISPLAY 'MQGET FAIL RC=' REASON
              EXEC CICS SYNCPOINT ROLLBACK END-EXEC
              GO TO MQ-CLOSE-BOTH
           END-IF.

           DISPLAY 'MQGET OK LEN=' W03-DATA-LENGTH.

           MOVE MQMD-MSGID TO MQMD-CORRELID.
           MOVE MQMI-NONE  TO MQMD-MSGID.

           MOVE REQ-DATA(1:W03-DATA-LENGTH) TO WS-XML-REQUEST.

           PERFORM PARSE-XML-REQUEST.

           IF WS-REQUEST-TYPE = 'ACTIVE'
               IF HAU-STATUS-CODE NOT = 'ERR '
                   PERFORM PROCESS-ACTIVE-BY-USER
               END-IF
           ELSE
               IF WS-REQUEST-TYPE = 'RETURN'
                   IF HRR-STATUS-CODE NOT = 'ERR '
                       PERFORM PROCESS-RETURN
                   END-IF
               ELSE
                   IF HBR-STATUS-CODE NOT = 'ERR '
                       PERFORM PROCESS-BORROW
                   END-IF
               END-IF
           END-IF.

           PERFORM BUILD-XML-RESPONSE.

           MOVE MQMT-REPLY              TO MQMD-MSGTYPE.
           MOVE MQFMT-STRING            TO MQMD-FORMAT.
           MOVE MQENC-NATIVE            TO MQMD-ENCODING.
           MOVE 1047                    TO MQMD-CODEDCHARSETID.

           MOVE MQPMO-VERSION-1         TO MQPMO-VERSION.
           MOVE MQPMO-SYNCPOINT         TO MQPMO-OPTIONS.
           ADD  MQPMO-FAIL-IF-QUIESCING TO MQPMO-OPTIONS.

           CALL 'MQPUT' USING HCONN
                             HOBJ-REP
                             MQM-MESSAGE-DESCRIPTOR
                             MQM-PUT-MESSAGE-OPTIONS
                             RSP-DATA-LEN
                             RSP-DATA
                             COMPCODE
                             REASON.
           IF COMPCODE NOT = MQCC-OK
               DISPLAY 'MQPUT FAIL CC=' COMPCODE
               DISPLAY 'MQPUT FAIL RC=' REASON
               EXEC CICS SYNCPOINT ROLLBACK END-EXEC
           ELSE
               DISPLAY 'MQPUT OK'.
               EXEC CICS SYNCPOINT END-EXEC
           END-IF.

       MQ-CLOSE-BOTH.
           IF HOBJ-REP NOT = 0
               CALL 'MQCLOSE' USING HCONN
                                   HOBJ-REP
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

           DISPLAY 'LIBMQCIC ENDING'.
           EXEC CICS RETURN END-EXEC.

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

           CONTINUE.

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

           CONTINUE.

       PROCESS-ACTIVE-BY-USER.
           MOVE SPACES TO HOST-ACTIVE-BY-USER-RESPONSE.
           MOVE HAU-USER-ID TO HAU-USER-ID-R.
           MOVE 0 TO WS-ACTIVE-LOAN-COUNT HAU-LOAN-COUNT.
           MOVE SPACES TO HAU-LOANS.

           IF HAU-USER-ID = SPACES
               MOVE 'ERR ' TO HAU-STATUS-CODE
               MOVE 'Missing userId' TO HAU-MESSAGE
               EXIT
           END-IF

           EXEC SQL
              OPEN CUR-ACTIVE-LOANS
           END-EXEC
           IF SQLCODE NOT = 0
               PERFORM SQL-ERROR
               EXIT
           END-IF

           PERFORM UNTIL WS-ACTIVE-LOAN-COUNT >= 50
               EXEC SQL
                  FETCH CUR-ACTIVE-LOANS
                    INTO :WS-ACTIVE-LOAN-ID-NUM, :WS-ACTIVE-BOOK-ID
               END-EXEC
               IF SQLCODE = 0
                   ADD 1 TO WS-ACTIVE-LOAN-COUNT
                   MOVE WS-ACTIVE-LOAN-ID-NUM TO WS-NEW-LOAN-NUM
                   MOVE SPACES TO WS-NEW-LOAN-ID
                   MOVE 'L'    TO WS-NEW-LOAN-ID (1:1)
                   MOVE WS-NEW-LOAN-NUM TO WS-NEW-LOAN-ID (2:9)
                   MOVE WS-NEW-LOAN-ID
                     TO HAU-LOAN-ID (WS-ACTIVE-LOAN-COUNT)
                   MOVE WS-ACTIVE-BOOK-ID
                     TO HAU-BOOK-ID (WS-ACTIVE-LOAN-COUNT)
               ELSE
                   IF SQLCODE = 100
                       EXIT PERFORM
                   ELSE
                       PERFORM SQL-ERROR
                       EXIT PERFORM
                   END-IF
               END-IF
           END-PERFORM

           EXEC SQL
              CLOSE CUR-ACTIVE-LOANS
           END-EXEC

           IF HAU-STATUS-CODE NOT = 'ERR '
               MOVE WS-ACTIVE-LOAN-COUNT TO HAU-LOAN-COUNT
               MOVE 'OK' TO HAU-STATUS-CODE
               MOVE 'Active loans returned' TO HAU-MESSAGE
           END-IF
           EXIT.

       BUILD-RESPONSE.
           MOVE SPACES TO RSP-DATA.
           IF WS-REQUEST-TYPE = 'ACTIVE'
               MOVE HOST-ACTIVE-BY-USER-RESPONSE TO RSP-DATA
           ELSE
               IF WS-REQUEST-TYPE = 'RETURN'
                   MOVE HOST-RETURN-RESPONSE TO RSP-DATA
               ELSE
                   MOVE HOST-BORROW-RESPONSE TO RSP-DATA
               END-IF
           END-IF.
           EXIT.

       SQL-ERROR.
           MOVE SPACES TO WS-SQL-MSG WS-SQLSTATE-DISP.
           MOVE SPACES TO WS-SQLERRMC-DISP.
           MOVE SQLCODE  TO WS-SQLCODE-EDIT.
           MOVE SQLSTATE TO WS-SQLSTATE-DISP.
           MOVE SQLERRMC TO WS-SQLERRMC-DISP.

           STRING 'SQL ERROR ' DELIMITED BY SIZE
               WS-SQLCODE-EDIT DELIMITED BY SIZE
               ' ST=' DELIMITED BY SIZE
               WS-SQLSTATE-DISP DELIMITED BY SIZE
             INTO WS-SQL-MSG.
           IF WS-REQUEST-TYPE = 'ACTIVE'
               MOVE 'ERR ' TO HAU-STATUS-CODE
               MOVE WS-SQL-MSG TO HAU-MESSAGE
           ELSE
               IF WS-REQUEST-TYPE = 'RETURN'
                   MOVE 'ERR ' TO HRR-STATUS-CODE
                   MOVE WS-SQL-MSG TO HRR-MESSAGE
               ELSE
                   MOVE 'ERR ' TO HBR-STATUS-CODE
                   MOVE WS-SQL-MSG TO HBR-MESSAGE
               END-IF
           END-IF.
           CONTINUE.
           EXIT.

      ******************************************************************
      ** Parse XML request into HOST-BORROW-REQUEST
      ******************************************************************
       PARSE-XML-REQUEST.
           MOVE SPACES TO HOST-BORROW-REQUEST HOST-RETURN-REQUEST
               HOST-ACTIVE-BY-USER-REQUEST.
           MOVE 'OK'    TO HBR-STATUS-CODE HRR-STATUS-CODE
               HAU-STATUS-CODE.
           MOVE SPACES  TO HBR-MESSAGE HRR-MESSAGE HAU-MESSAGE.
           MOVE SPACES  TO WS-REQUEST-TYPE.

           MOVE 0 TO WS-ACTIVE-REQ-COUNT.
           INSPECT WS-XML-REQUEST
               TALLYING WS-ACTIVE-REQ-COUNT
               FOR ALL "<HostActiveLoansByUserRequest".

           MOVE 0 TO WS-RETURN-COUNT.
           INSPECT WS-XML-REQUEST
               TALLYING WS-RETURN-COUNT
               FOR ALL "<HostReturnRequest".

           IF WS-ACTIVE-REQ-COUNT > 0
               MOVE 'ACTIVE' TO WS-REQUEST-TYPE
               PERFORM EXTRACT-ACTIVE-USER-ID
               IF HAU-USER-ID = SPACES
                   MOVE 'ERR ' TO HAU-STATUS-CODE
                   MOVE 'Invalid XML' TO HAU-MESSAGE
               END-IF
           ELSE
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

       EXTRACT-ACTIVE-USER-ID.
           MOVE 0 TO WS-START WS-END WS-LEN.
           INSPECT WS-XML-REQUEST
               TALLYING WS-START
               FOR CHARACTERS BEFORE WS-TAG-ACTIVE-USERID-START.
           IF WS-START >= LENGTH OF WS-XML-REQUEST
               EXIT
           END-IF
           COMPUTE WS-START = WS-START + LENGTH
                OF WS-TAG-ACTIVE-USERID-START.
           INSPECT WS-XML-REQUEST
               TALLYING WS-END
               FOR CHARACTERS BEFORE WS-TAG-ACTIVE-USERID-END.
           IF WS-END <= WS-START
               EXIT
           END-IF
           COMPUTE WS-LEN = WS-END - WS-START.
           IF WS-LEN > 0
               MOVE WS-XML-REQUEST (WS-START + 1: WS-LEN) TO HAU-USER-ID
           END-IF
           DISPLAY 'EXTRACT-ACTIVE-USER-ID: ' HAU-USER-ID
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
           IF WS-REQUEST-TYPE = 'ACTIVE'
               MOVE 1 TO WS-PTR
               STRING
                  '<HostActiveLoansByUserResponse ' DELIMITED BY SIZE
                  ' xmlns="http://company.com/library/host/schema">'
                                         DELIMITED BY SIZE
                  '<statusCode>'         DELIMITED BY SIZE
                  FUNCTION TRIM(HAU-STATUS-CODE)   DELIMITED BY SIZE
                  '</statusCode>'        DELIMITED BY SIZE
                  '<message>'            DELIMITED BY SIZE
                  FUNCTION TRIM(HAU-MESSAGE) DELIMITED BY SIZE
                  '</message>'           DELIMITED BY SIZE
                  '<userId>'             DELIMITED BY SIZE
                  FUNCTION TRIM(HAU-USER-ID-R) DELIMITED BY SIZE
                  '</userId>'            DELIMITED BY SIZE
                INTO WS-XML-RESPONSE WITH POINTER WS-PTR
               END-STRING
               MOVE 1 TO WS-INDEX
               PERFORM UNTIL WS-INDEX > HAU-LOAN-COUNT
                   STRING
                      '<loan>'             DELIMITED BY SIZE
                      '<loanId>'           DELIMITED BY SIZE
                      FUNCTION TRIM(HAU-LOAN-ID (WS-INDEX))
                                           DELIMITED BY SIZE
                      '</loanId>'          DELIMITED BY SIZE
                      '<bookId>'           DELIMITED BY SIZE
                      FUNCTION TRIM(HAU-BOOK-ID (WS-INDEX))
                                           DELIMITED BY SIZE
                      '</bookId>'          DELIMITED BY SIZE
                      '</loan>'            DELIMITED BY SIZE
                    INTO WS-XML-RESPONSE WITH POINTER WS-PTR
                   END-STRING
                   ADD 1 TO WS-INDEX
               END-PERFORM
               STRING
                  '</HostActiveLoansByUserResponse>' DELIMITED BY SIZE
                INTO WS-XML-RESPONSE WITH POINTER WS-PTR
               END-STRING
           ELSE
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
               END-IF
           END-IF.
           MOVE SPACES TO RSP-DATA.
           MOVE WS-XML-RESPONSE TO RSP-DATA.
           COMPUTE RSP-DATA-LEN =
               FUNCTION LENGTH(
                   FUNCTION TRIM(WS-XML-RESPONSE TRAILING)).
           EXIT.

       END PROGRAM LIBMQCIC.
