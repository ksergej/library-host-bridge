CBL NOXREF NOMAP NOOFFSET NOSOURCE
       IDENTIFICATION DIVISION.
       PROGRAM-ID. LIBMQCIC.

      *****************************************************************
      * CICS MQ Host Bridge (Stage 1 MVP)
      *
      * - Manually invoked by CICS transaction (e.g., LIBT)
      * - Processes ONE message from MQ request queue and posts reply
      * - Commit/Rollback via EXEC CICS SYNCPOINT
      * - Reply CorrelId = request MsgId (mandatory)
      *
      * Derived from batch program: LIBMQTST
      *****************************************************************

       ENVIRONMENT DIVISION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.

      * CICS control blocks
       01  DFHEIBLK.
           COPY DFHEIBLK.

       EXEC SQL INCLUDE SQLCA END-EXEC.

       01  WS-SQLCODE-EDIT      PIC -ZZZ,ZZZ,ZZ9 USAGE DISPLAY.

      * MQ structures
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

      * MQ names (MVP: constants; derived from prior batch PARAMS DD)
      *   QMGR=CSQ9
      *   REQ =Z88011.MQZ3.QLOCAL
      *   RPLY=Z88011.MQZ3.REPLYTO.QLOCAL
      * Replace with TSQ/VSAM/COMMAREA config later.
       01  WS-QMGR-NAME       PIC X(48) VALUE 'CSQ9'.
       01  WS-REQ-QUEUE       PIC X(48) VALUE 'Z88011.MQZ3.QLOCAL'.
       01  WS-REP-QUEUE       PIC X(48) VALUE 'Z88011.MQZ3.REPLYTO.QLOCAL'.
      * MQ handles / status
       01  HCONN              PIC S9(9) COMP VALUE 0.
       01  HOBJ-REQ           PIC S9(9) COMP VALUE 0.
       01  HOBJ-REP           PIC S9(9) COMP VALUE 0.
       01  COMPCODE           PIC S9(9) COMP VALUE 0.
       01  REASON             PIC S9(9) COMP VALUE 0.

      * Request / reply buffers (same sizes as LIBMQTST)
       01  REQ-DATA           PIC X(8192).
       01  REQ-DATA-LEN       PIC S9(9) COMP-5 VALUE 8192.
       01  RSP-DATA           PIC X(8192).
       01  RSP-DATA-LEN       PIC S9(9) COMP-5 VALUE 0.

      * Helper fields
       01  W03-DATA-LENGTH    PIC S9(9) COMP-5 VALUE 0.
       01  WS-REQUEST-TYPE    PIC X(6) VALUE SPACES.
       01  WS-PTR-1           PIC S9(9) COMP-5 VALUE 1.
       01  WS-ACTIVE-COUNT    PIC S9(9) COMP-5 VALUE 0.
       01  WS-LOAN-ID-NUM     PIC S9(9) COMP-5 VALUE 0.
       01  WS-ACTIVE-LOAN-ID-NUM PIC S9(9) COMP-5 VALUE 0.
       01  WS-ACTIVE-BOOK-ID  PIC X(10) VALUE SPACES.
       01  WS-ACTIVE-LOAN-COUNT PIC S9(9) COMP-5 VALUE 0.

      * Save request MsgId for correlation
       01  WS-REQ-MSGID.
           05 WS-REQ-MSGID-BYTE PIC X OCCURS 24.

      * Existing payload layout copybook
           COPY LIBLOAN.

      * Cursor used by ACTIVE-BY-USER
           EXEC SQL
           DECLARE CUR-ACTIVE-LOANS CURSOR FOR
               SELECT LOAN_ID_NUM, BOOK_ID
                 FROM LOAN
                WHERE USER_ID = :HAU-USER-ID
                  AND RETURN_DATE IS NULL
                ORDER BY LOAN_ID_NUM
           END-EXEC.

      * Minimal error message buffer (used by SQL-ERROR)
       01  WS-SQL-MSG          PIC X(120) VALUE SPACES.

       LINKAGE SECTION.
       01  DFHCOMMAREA.
           05  FILLER          PIC X OCCURS 1 TO 32767
                               DEPENDING ON EIBCALEN.

       PROCEDURE DIVISION USING DFHCOMMAREA.

       MAIN-SECTION.
      * Ensure we return cleanly to CICS on any abend
           EXEC CICS HANDLE ABEND LABEL(ABEND-HANDLER) END-EXEC.

           MOVE SPACES TO REQ-DATA RSP-DATA.
           MOVE 0      TO W03-DATA-LENGTH RSP-DATA-LEN.
           MOVE 1      TO WS-PTR-1.

           DISPLAY 'LIBMQCIC START EIBTRNID=' EIBTRNID
                   ' EIBTASKN=' EIBTASKN.

      * --- MQCONN (use default QM if WS-QMGR-NAME is spaces) ---
           CALL 'MQCONN' USING WS-QMGR-NAME
                               HCONN
                               COMPCODE
                               REASON.
           IF COMPCODE NOT = MQCC-OK
               DISPLAY 'MQCONN FAILED RC=' REASON
               GO TO CLEAN-RETURN
           END-IF.

      * --- OPEN request queue ---
           MOVE MQOD-VERSION-4 TO MQOD-VERSION.
           MOVE WS-REQ-QUEUE    TO MQOD-OBJECTNAME.

           CALL 'MQOPEN' USING HCONN
                               MQM-OBJECT-DESCRIPTOR
                               MQOO-INPUT-SHARED
                               HOBJ-REQ
                               COMPCODE
                               REASON.
           IF COMPCODE NOT = MQCC-OK
               DISPLAY 'MQOPEN REQ FAILED RC=' REASON
               GO TO MQ-DISCONNECT
           END-IF.

      * --- OPEN reply queue ---
           MOVE MQOD-VERSION-4 TO MQOD-VERSION.
           MOVE WS-REP-QUEUE    TO MQOD-OBJECTNAME.

           CALL 'MQOPEN' USING HCONN
                               MQM-OBJECT-DESCRIPTOR
                               MQOO-OUTPUT
                               HOBJ-REP
                               COMPCODE
                               REASON.
           IF COMPCODE NOT = MQCC-OK
               DISPLAY 'MQOPEN REP FAILED RC=' REASON
               GO TO MQ-CLOSE-REQ
           END-IF.

      * --- MQGET one message (MVP: NO_WAIT + SYNCPOINT) ---
           MOVE MQGMO-VERSION-1         TO MQGMO-VERSION.
           MOVE MQMT-DATAGRAM           TO MQMD-MSGTYPE.

           MOVE MQGMO-NO-WAIT           TO MQGMO-OPTIONS
           ADD  MQGMO-CONVERT           TO MQGMO-OPTIONS
           ADD  MQGMO-FAIL-IF-QUIESCING TO MQGMO-OPTIONS
           ADD  MQGMO-SYNCPOINT         TO MQGMO-OPTIONS.

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
              IF REASON = MQRC-NO-MSG-AVAILABLE
                  DISPLAY 'NO MESSAGE AVAILABLE; END TASK'
                  GO TO MQ-CLOSE-BOTH
              END-IF
              DISPLAY 'MQGET FAILED CC=' COMPCODE ' RC=' REASON
              GO TO ROLLBACK-AND-RETURN
           END-IF.

      * Save request MsgId for reply correlation
           MOVE MQMD-MSGID TO WS-REQ-MSGID.

      * Route + execute DB2 logic
           PERFORM PROCESS-REQUEST.

      * Build reply body into RSP-DATA and compute length
           PERFORM BUILD-RESPONSE.
      * Preferred: use pointer-derived length to avoid trailing blanks
           COMPUTE RSP-DATA-LEN = WS-PTR-1 - 1.
           IF RSP-DATA-LEN < 0
              MOVE 0 TO RSP-DATA-LEN
           END-IF.

      * --- MQPUT reply (SYNCPOINT) ---
           MOVE MQPMO-VERSION-1         TO MQPMO-VERSION.
           MOVE MQPMO-NO-SYNCPOINT      TO MQPMO-OPTIONS
           ADD  MQPMO-SYNCPOINT         TO MQPMO-OPTIONS
           ADD  MQPMO-FAIL-IF-QUIESCING TO MQPMO-OPTIONS.

      * Correlation rule (mandatory)
           MOVE WS-REQ-MSGID TO MQMD-CORRELID
           MOVE MQMI-NONE    TO MQMD-MSGID.

           CALL 'MQPUT' USING HCONN
                             HOBJ-REP
                             MQM-MESSAGE-DESCRIPTOR
                             MQM-PUT-MESSAGE-OPTIONS
                             RSP-DATA-LEN
                             RSP-DATA
                             COMPCODE
                             REASON.
           IF COMPCODE NOT = MQCC-OK
              DISPLAY 'MQPUT FAILED RC=' REASON
              GO TO ROLLBACK-AND-RETURN
           END-IF.

      * Commit MQ+DB2
           EXEC CICS SYNCPOINT END-EXEC.
           DISPLAY 'SYNCPOINT COMMIT OK'.

           GO TO MQ-CLOSE-BOTH.

       ROLLBACK-AND-RETURN.
           EXEC CICS SYNCPOINT ROLLBACK END-EXEC.
           DISPLAY 'SYNCPOINT ROLLBACK DONE'.
           GO TO MQ-CLOSE-BOTH.

       MQ-CLOSE-BOTH.
      * Close reply then request (ignore close errors for MVP)
           IF HOBJ-REP NOT = 0
              CALL 'MQCLOSE' USING HCONN HOBJ-REP MQCO-NONE
                                   COMPCODE REASON
           END-IF.
           IF HOBJ-REQ NOT = 0
              CALL 'MQCLOSE' USING HCONN HOBJ-REQ MQCO-NONE
                                   COMPCODE REASON
           END-IF.
           GO TO MQ-DISCONNECT.

       MQ-CLOSE-REQ.
           IF HOBJ-REQ NOT = 0
              CALL 'MQCLOSE' USING HCONN HOBJ-REQ MQCO-NONE
                                   COMPCODE REASON
           END-IF.
           GO TO MQ-DISCONNECT.

       MQ-DISCONNECT.
           CALL 'MQDISC' USING HCONN
                               COMPCODE
                               REASON.

           DISPLAY 'LIBMQTST ENDING'.
           EXEC CICS RETURN END-EXEC.

      ******************************************************************
      ** Process the request using DB2 and build response
      ******************************************************************

       CLEAN-RETURN.
           EXEC CICS RETURN END-EXEC.

       ABEND-HANDLER.
           DISPLAY 'ABEND in LIBMQCIC EIBRESP=' EIBRESP
                   ' EIBRESP2=' EIBRESP2.
           EXEC CICS SYNCPOINT ROLLBACK END-EXEC.
           EXEC CICS RETURN END-EXEC.

      *****************************************************************
      * Request routing + DB2 logic (adapted from LIBMQTST)
      *****************************************************************

       PROCESS-REQUEST.
           MOVE SPACES TO WS-REQUEST-TYPE.
           IF REQ-DATA(1:32) = SPACES
               MOVE 'ERR' TO WS-REQUEST-TYPE
           END-IF

      * Very simple routing (same idea as LIBMQTST; can be hardened later)
           IF REQ-DATA(1:200) CONTAINS '<HostBorrowRequest'
               MOVE 'BORROW' TO WS-REQUEST-TYPE
           ELSE
               IF REQ-DATA(1:200) CONTAINS '<HostReturnRequest'
                   MOVE 'RETURN' TO WS-REQUEST-TYPE
               ELSE
                   IF REQ-DATA(1:300) CONTAINS '<HostActiveLoansByUserRequest'
                       MOVE 'ACTIVE' TO WS-REQUEST-TYPE
                   ELSE
                       MOVE 'ERR' TO WS-REQUEST-TYPE
                   END-IF
               END-IF
           END-IF

           EVALUATE WS-REQUEST-TYPE
              WHEN 'BORROW'
                 PERFORM PROCESS-BORROW
              WHEN 'RETURN'
                 PERFORM PROCESS-RETURN
              WHEN 'ACTIVE'
                 PERFORM PROCESS-ACTIVE-BY-USER
              WHEN OTHER
                 MOVE 'ERRO' TO HBR-STATUS-CODE
                 MOVE 'Unknown request' TO HBR-MESSAGE
           END-EVALUATE
           .

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
           MOVE SPACES TO WS-SQL-MSG.
           MOVE SQLCODE TO WS-SQLCODE-EDIT.

           STRING 'SQL ERROR ' DELIMITED BY SIZE
               WS-SQLCODE-EDIT DELIMITED BY SIZE
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
           EXEC SQL ROLLBACK END-EXEC.
           EXIT.

      ******************************************************************
      ** Parse XML request into HOST-BORROW-REQUEST
      ******************************************************************

      *****************************************************************
      * NOTE:
      * - MQ queue names are hardcoded for MVP. Replace with
      *   SIT/ENV/configuration once the end-to-end path works.
      * - Routing uses simple substring checks; harden later.
      * - Ensure DB2 package/plan is correct for CICS runtime.
      *****************************************************************
