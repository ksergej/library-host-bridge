CBL NOXREF NOMAP NOOFFSET NOSOURCE
       IDENTIFICATION DIVISION.
       PROGRAM-ID. LIBMQCIC.

       DATA DIVISION.
       WORKING-STORAGE SECTION.

       01  MQM-CONSTANTS.
           COPY CMQV.

       01  WS-RESP              PIC S9(8) COMP VALUE 0.
       01  WS-RESP2             PIC S9(8) COMP VALUE 0.

       01  WS-QMGR-NAME         PIC X(48) VALUE SPACES.
       01  WS-HCONN             PIC S9(9) COMP VALUE 0.
       01  WS-COMPCODE          PIC S9(9) COMP VALUE 0.
       01  WS-REASON            PIC S9(9) COMP VALUE 0.

       01  WS-COMPCODE-DISP     PIC -ZZZ,ZZZ,ZZ9.
       01  WS-REASON-DISP       PIC -ZZZ,ZZZ,ZZ9.

       01  WS-MSG-START         PIC X(40)
           VALUE 'STEP1 START'.
       01  WS-MSG-OK            PIC X(80) VALUE SPACES.
       01  WS-MSG-FAIL          PIC X(80) VALUE SPACES.
       01  WS-MSG-CICSERR       PIC X(40)
           VALUE 'CICS ERROR BEFORE RETURN'.

       PROCEDURE DIVISION.

       MAIN-SECTION.

      * Step 1: visible entry marker
           MOVE 0 TO WS-RESP WS-RESP2
           EXEC CICS SEND TEXT
                FROM(WS-MSG-START)
                LENGTH(11)
                ERASE
                RESP(WS-RESP)
                RESP2(WS-RESP2)
           END-EXEC
           IF WS-RESP NOT = DFHRESP(NORMAL)
              GO TO CICS-ERROR
           END-IF

      * Step 2: minimal MQ connect only
           MOVE 0 TO WS-HCONN WS-COMPCODE WS-REASON

           CALL 'MQCONN' USING WS-QMGR-NAME
                               WS-HCONN
                               WS-COMPCODE
                               WS-REASON

      * Step 3: show MQCONN result on terminal
           MOVE WS-COMPCODE TO WS-COMPCODE-DISP
           MOVE WS-REASON   TO WS-REASON-DISP

           IF WS-COMPCODE = MQCC-OK
              STRING 'MQCONN OK CC='
                     DELIMITED BY SIZE
                     WS-COMPCODE-DISP
                     DELIMITED BY SIZE
                     ' RC='
                     DELIMITED BY SIZE
                     WS-REASON-DISP
                     DELIMITED BY SIZE
                INTO WS-MSG-OK
           ELSE
              STRING 'MQCONN FAIL CC='
                     DELIMITED BY SIZE
                     WS-COMPCODE-DISP
                     DELIMITED BY SIZE
                     ' RC='
                     DELIMITED BY SIZE
                     WS-REASON-DISP
                     DELIMITED BY SIZE
                INTO WS-MSG-FAIL
           END-IF

           MOVE 0 TO WS-RESP WS-RESP2
           IF WS-COMPCODE = MQCC-OK
              EXEC CICS SEND TEXT
                   FROM(WS-MSG-OK)
                   LENGTH(40)
                   ERASE
                   RESP(WS-RESP)
                   RESP2(WS-RESP2)
              END-EXEC
           ELSE
              EXEC CICS SEND TEXT
                   FROM(WS-MSG-FAIL)
                   LENGTH(42)
                   ERASE
                   RESP(WS-RESP)
                   RESP2(WS-RESP2)
              END-EXEC
           END-IF

           IF WS-RESP NOT = DFHRESP(NORMAL)
              GO TO CICS-ERROR
           END-IF

      * Clean disconnect only if connect succeeded
           IF WS-COMPCODE = MQCC-OK
              CALL 'MQDISC' USING WS-HCONN
                                  WS-COMPCODE
                                  WS-REASON
           END-IF

           MOVE 0 TO WS-RESP WS-RESP2
           EXEC CICS RETURN
                RESP(WS-RESP)
                RESP2(WS-RESP2)
           END-EXEC

           GO TO CICS-ERROR.

       CICS-ERROR.
           EXEC CICS SEND TEXT
                FROM(WS-MSG-CICSERR)
                LENGTH(24)
                ERASE
           END-EXEC

           EXEC CICS ABEND
                ABCODE('T001')
                NODUMP
           END-EXEC.

       END PROGRAM LIBMQCIC.
