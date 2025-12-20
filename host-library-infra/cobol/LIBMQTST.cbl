CBL NOXREF NOMAP NOOFFSET
       IDENTIFICATION DIVISION.
       PROGRAM-ID. LIBMQTST.

       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.

       EXEC SQL INCLUDE SQLCA END-EXEC.

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
       01  WS-WAIT-MS         PIC S9(9) COMP VALUE 5000.
       01  WS-SYSIN-LINE      PIC X(256) VALUE SPACES.
       01  WS-SYSIN-EOF       PIC X VALUE 'N'.
       01  WS-KEY             PIC X(16).
       01  WS-VALUE           PIC X(128).
       01  WS-WAIT-TEXT       PIC X(16) VALUE SPACES.

           COPY LIBLOAN.

       01  HCONN        PIC S9(9) COMP.
       01  HOBJ-REQ     PIC S9(9) COMP.
       01  HOBJ-REP     PIC S9(9) COMP.
       01  COMPCODE     PIC S9(9) COMP.
       01  REASON       PIC S9(9) COMP.

       01  REQ-DATA             PIC X(256).
       01  RSP-DATA             PIC X(256).
       01  REQ-DATA-LEN         PIC S9(9) COMP VALUE 0.
       01  RSP-DATA-LEN         PIC S9(9) COMP VALUE 0.

       01  WS-ACTIVE-COUNT      PIC S9(9) COMP VALUE 0.
       01  WS-LOAN-ID-NUM       PIC S9(9) COMP VALUE 0.
       01  WS-NEW-LOAN-NUM      PIC 9(9)    VALUE 0.
       01  WS-NEW-LOAN-ID       PIC X(10)   VALUE SPACES.
       01  WS-PADDED            PIC X(9)    VALUE SPACES.

       01  WS-SQL-MSG           PIC X(80)   VALUE SPACES.
       01  WS-XML-REQUEST       PIC X(2048) VALUE SPACES.
       01  WS-XML-RESPONSE      PIC X(2048) VALUE SPACES.
       01  WS-TAG-USER-START    PIC X(8)    VALUE "<userId>".
       01  WS-TAG-USER-END      PIC X(9)    VALUE "</userId>".
       01  WS-TAG-BOOK-START    PIC X(8)    VALUE "<bookId>".
       01  WS-TAG-BOOK-END      PIC X(9)    VALUE "</bookId>".
       01  WS-START             PIC S9(9) COMP VALUE 0.
       01  WS-END               PIC S9(9) COMP VALUE 0.
       01  WS-LEN               PIC S9(9) COMP VALUE 0.

       PROCEDURE DIVISION.

       MAIN-SECTION.

           DISPLAY 'LIBMQTST STARTING'.

           PERFORM READ-SYSIN-SETTINGS.
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

           MOVE MQGMO-VERSION-1      TO MQGMO-VERSION.
           MOVE MQGMO-WAIT           TO MQGMO-OPTIONS.
           MOVE WS-WAIT-MS           TO MQGMO-WAITINTERVAL.

           MOVE MQMD-VERSION-1       TO MQMD-VERSION.
           MOVE MQMT-DATAGRAM        TO MQMD-MSGTYPE.

           COMPUTE REQ-DATA-LEN = FUNCTION LENGTH(REQ-DATA).

           CALL 'MQGET' USING HCONN
                             HOBJ-REQ
                             MQM-MESSAGE-DESCRIPTOR
                             MQM-GET-MESSAGE-OPTIONS
                             REQ-DATA-LEN
                             REQ-DATA
                             COMPCODE
                             REASON.
           IF COMPCODE NOT = MQCC-OK
               DISPLAY 'MQGET FAILED, REASON=' REASON
               GO TO MQ-CLOSE-BOTH
           END-IF.

           MOVE MQMD-MSGID      TO MQMD-CORRELID.
           MOVE MQMI-NONE       TO MQMD-MSGID.

           MOVE REQ-DATA TO WS-XML-REQUEST.

           PERFORM PARSE-XML-REQUEST.

           IF HBR-STATUS-CODE NOT = 'ERR '
               PERFORM PROCESS-REQUEST
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
       PROCESS-REQUEST.
           MOVE SPACES TO HOST-BORROW-RESPONSE.
           MOVE HBR-USER-ID        TO HBR-USER-ID-R.
           MOVE HBR-BOOK-ID        TO HBR-BOOK-ID-R.

           EXEC SQL
              SELECT COUNT(*)
                INTO :WS-ACTIVE-COUNT
                FROM LIBRARY.LOAN
               WHERE BOOK_ID    = :HBR-BOOK-ID
                 AND RETURN_DATE IS NULL
           END-EXEC

           IF SQLCODE NOT = 0
               PERFORM SQL-ERROR
               GO TO BUILD-RESPONSE
           END-IF

           IF WS-ACTIVE-COUNT > 0
               MOVE 'BUSY' TO HBR-STATUS-CODE
               MOVE 'Book already on loan' TO HBR-MESSAGE
               GO TO BUILD-RESPONSE
           END-IF

           EXEC SQL
              INSERT INTO LIBRARY.LOAN
                   (USER_ID, BOOK_ID, LOAN_DATE, DUE_DATE, RETURN_DATE)
              VALUES (:HBR-USER-ID, :HBR-BOOK-ID,
                      CURRENT DATE, CURRENT DATE + 14 DAYS, NULL)
           END-EXEC

           IF SQLCODE NOT = 0
               PERFORM SQL-ERROR
               GO TO BUILD-RESPONSE
           END-IF

           EXEC SQL
              VALUES IDENTITY_VAL_LOCAL()
                INTO :WS-LOAN-ID-NUM
           END-EXEC

           IF SQLCODE NOT = 0
               PERFORM SQL-ERROR
               GO TO BUILD-RESPONSE
           END-IF

           MOVE WS-LOAN-ID-NUM TO WS-NEW-LOAN-NUM
           MOVE ALL '0' TO WS-PADDED
           STRING WS-PADDED DELIMITED BY SIZE
                  WS-NEW-LOAN-NUM DELIMITED BY SIZE
             INTO WS-PADDED
           MOVE 'L' TO WS-NEW-LOAN-ID (1:1)
           MOVE WS-PADDED( LENGTH OF WS-PADDED - 8:9 )
             TO WS-NEW-LOAN-ID (2:9)

           MOVE WS-NEW-LOAN-ID TO HBR-LOAN-ID
           MOVE 'OK'           TO HBR-STATUS-CODE
           MOVE 'Loan created' TO HBR-MESSAGE

           EXEC SQL COMMIT END-EXEC.

       BUILD-RESPONSE.
           MOVE SPACES TO RSP-DATA.
           MOVE HOST-BORROW-RESPONSE TO RSP-DATA.
           EXIT.

       SQL-ERROR.
           MOVE 'ERR ' TO HBR-STATUS-CODE.
           MOVE SPACES TO WS-SQL-MSG.
           MOVE SQLCODE TO WS-SQLCODE-EDIT.

           STRING 'SQL ERROR ' DELIMITED BY SIZE
               WS-SQLCODE-EDIT DELIMITED BY SIZE
             INTO WS-SQL-MSG.
           MOVE WS-SQL-MSG TO HBR-MESSAGE.
           EXEC SQL ROLLBACK END-EXEC.
           EXIT.

      ******************************************************************
      ** Parse XML request into HOST-BORROW-REQUEST
      ******************************************************************
       PARSE-XML-REQUEST.
           MOVE SPACES TO HOST-BORROW-REQUEST.
           MOVE 'OK'    TO HBR-STATUS-CODE.
           MOVE SPACES  TO HBR-MESSAGE.

           PERFORM EXTRACT-USER.
           PERFORM EXTRACT-BOOK.

           IF HBR-USER-ID = SPACES OR HBR-BOOK-ID = SPACES
               MOVE 'ERR ' TO HBR-STATUS-CODE
               MOVE 'Invalid XML' TO HBR-MESSAGE
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
           EXIT.

      ******************************************************************
      ** Build XML response from HOST-BORROW-RESPONSE
      ******************************************************************
       BUILD-XML-RESPONSE.
           MOVE SPACES TO WS-XML-RESPONSE.
           STRING
              '<HostBorrowResponse>' DELIMITED BY SIZE
              '<loanId>'             DELIMITED BY SIZE
              HBR-LOAN-ID            DELIMITED BY SIZE
              '</loanId>'            DELIMITED BY SIZE
              '<userId>'             DELIMITED BY SIZE
              HBR-USER-ID-R          DELIMITED BY SIZE
              '</userId>'            DELIMITED BY SIZE
              '<bookId>'             DELIMITED BY SIZE
              HBR-BOOK-ID-R          DELIMITED BY SIZE
              '</bookId>'            DELIMITED BY SIZE
              '<statusCode>'         DELIMITED BY SIZE
              HBR-STATUS-CODE        DELIMITED BY SIZE
              '</statusCode>'        DELIMITED BY SIZE
              '<message>'            DELIMITED BY SIZE
              HBR-MESSAGE            DELIMITED BY SIZE
              '</message>'           DELIMITED BY SIZE
              '</HostBorrowResponse>' DELIMITED BY SIZE
            INTO WS-XML-RESPONSE
           END-STRING.
           MOVE SPACES TO RSP-DATA.
           MOVE WS-XML-RESPONSE TO RSP-DATA.
           EXIT.

      ******************************************************************
      ** Read SYSIN control cards (KEY=VALUE)
      ******************************************************************
       READ-SYSIN-SETTINGS.
           MOVE SPACES
             TO WS-QMGR-NAME WS-REQ-QUEUE WS-REP-QUEUE WS-WAIT-TEXT.
           MOVE 5000 TO WS-WAIT-MS.
           MOVE 'N'  TO WS-SYSIN-EOF.
           PERFORM UNTIL WS-SYSIN-EOF = 'Y'
              ACCEPT WS-SYSIN-LINE FROM SYSIN
              IF WS-SYSIN-LINE = SPACES
                 MOVE 'Y' TO WS-SYSIN-EOF
                 EXIT PERFORM
              END-IF
              PERFORM PARSE-SYSIN-LINE
           END-PERFORM
           EXIT.

      ******************************************************************
      ** Parse one SYSIN line KEY=VALUE (keys: QMGR, REQ, RPLY, WAIT_MS)
      ******************************************************************
       PARSE-SYSIN-LINE.
           MOVE FUNCTION TRIM(WS-SYSIN-LINE) TO WS-SYSIN-LINE.
           IF WS-SYSIN-LINE = SPACES
              EXIT
           END-IF
           MOVE SPACES TO WS-KEY WS-VALUE.
           UNSTRING WS-SYSIN-LINE DELIMITED BY '='
                    INTO WS-KEY WS-VALUE.
           INSPECT WS-KEY CONVERTING 'abcdefghijklmnopqrstuvwxyz'
                                TO 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.
           MOVE FUNCTION TRIM(WS-VALUE) TO WS-VALUE.
           EVALUATE WS-KEY
             WHEN 'QMGR'
                MOVE WS-VALUE TO WS-QMGR-NAME
             WHEN 'REQ'
                MOVE WS-VALUE TO WS-REQ-QUEUE
             WHEN 'RPLY'
                MOVE WS-VALUE TO WS-REP-QUEUE
             WHEN 'WAIT_MS'
                MOVE WS-VALUE TO WS-WAIT-TEXT
                IF WS-WAIT-TEXT NOT = SPACES
                   COMPUTE WS-WAIT-MS = FUNCTION NUMVAL(WS-WAIT-TEXT)
                   ON SIZE ERROR CONTINUE
                END-IF
             WHEN OTHER
                DISPLAY 'UNKNOWN SYSIN KEY=' WS-KEY
           END-EVALUATE.
           EXIT.

       END PROGRAM LIBMQTST.
