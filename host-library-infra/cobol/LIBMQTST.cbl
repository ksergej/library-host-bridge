IDENTIFICATION DIVISION.
PROGRAM-ID. LIBMQTST.

ENVIRONMENT DIVISION.
CONFIGURATION SECTION.

DATA DIVISION.
WORKING-STORAGE SECTION.

COPY CMQZC.
COPY CMQOD.
COPY CMQMD.
COPY CMQGMO.
COPY CMQPMO.

01  HCONN        PIC S9(9) COMP.
01  HOBJ-REQ     PIC S9(9) COMP.
01  HOBJ-REP     PIC S9(9) COMP.
01  COMPCODE     PIC S9(9) COMP.
01  REASON       PIC S9(9) COMP.

01  REQ-BUF.
    05 REQ-DATA  PIC X(256).

01  RSP-BUF.
    05 RSP-DATA  PIC X(256).

PROCEDURE DIVISION.

MAIN-SECTION.

    DISPLAY 'LIBMQTST STARTING'.

    CALL 'MQCONN' USING MQ-QMGR-NAME
                        HCONN
                        COMPCODE
                        REASON.
    IF COMPCODE NOT = MQCC-OK
        DISPLAY 'MQCONN FAILED, REASON=' REASON
        GOBACK
    END-IF.

    MOVE MQOD-VERSION-4 TO MQOD-VERSION.
    MOVE 'LIB.REQ.TEST' TO MQOD-OBJECT-NAME.
    CALL 'MQOPEN' USING HCONN
                        MQOD
                        MQOO-INPUT-SHARED
                        HOBJ-REQ
                        COMPCODE
                        REASON.
    IF COMPCODE NOT = MQCC-OK
        DISPLAY 'MQOPEN REQ FAILED, REASON=' REASON
        GO TO MQ-DISCONNECT
    END-IF.

    MOVE MQOD-VERSION-4 TO MQOD-VERSION.
    MOVE 'LIB.REP.TEST' TO MQOD-OBJECT-NAME.
    CALL 'MQOPEN' USING HCONN
                        MQOD
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
    MOVE 30000                TO MQGMO-WAIT-INTERVAL.

    MOVE MQMD-VERSION-1       TO MQMD-VERSION.
    MOVE MQMT-DATAGRAM        TO MQMD-MSGTYPE.

    CALL 'MQGET' USING HCONN
                      HOBJ-REQ
                      MQMD
                      MQGMO
                      LENGTH OF REQ-DATA
                      REQ-DATA
                      COMPCODE
                      REASON.
    IF COMPCODE NOT = MQCC-OK
        DISPLAY 'MQGET FAILED, REASON=' REASON
        GO TO MQ-CLOSE-BOTH
    END-IF.

    MOVE MQMD-MSGID      TO MQMD-CORRELID.
    MOVE MQMI-NONE       TO MQMD-MSGID.

    MOVE SPACES TO RSP-DATA.
    STRING 'ECHO: ' DELIMITED BY SIZE
           REQ-DATA DELIMITED BY SPACE
           INTO RSP-DATA.

    MOVE MQPMO-VERSION-1 TO MQPMO-VERSION.
    MOVE MQPMO-NO-SYNCPOINT TO MQPMO-OPTIONS.

    CALL 'MQPUT' USING HCONN
                      HOBJ-REP
                      MQMD
                      MQPMO
                      LENGTH OF RSP-DATA
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

END PROGRAM LIBMQTST.
