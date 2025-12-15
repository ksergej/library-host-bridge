//LIBMQRUN JOB (ACCT),'RUN LIBMQTST',
//         CLASS=A,MSGCLASS=X,NOTIFY=&SYSUID
//*-------------------------------------------------------------*
//*  IBM Z Xplore placeholder job to run MQ test LIBMQTST       *
//*  Replace &HLQ, &COBLOAD, &MQLOAD with real values:          *
//*    - &HLQ      : your HLQ (e.g. Z12345)                     *
//*    - &COBLOAD  : COBOL loadlib with LIBMQTST (e.g. &HLQ..LIB.LOAD) *
//*    - &MQLOAD   : IBM MQ loadlib (e.g. CSQ900.SCSQLOAD)      *
//*-------------------------------------------------------------*
//SET HLQ=Z12345
//SET COBLOAD=&HLQ..LIB.LOAD
//SET MQLOAD=CSQ900.SCSQLOAD
//*
//RUN     EXEC PGM=LIBMQTST,REGION=0M
//STEPLIB DD  DSN=&COBLOAD,DISP=SHR
//        DD  DSN=&MQLOAD,DISP=SHR
//SYSOUT  DD  SYSOUT=*
//*
