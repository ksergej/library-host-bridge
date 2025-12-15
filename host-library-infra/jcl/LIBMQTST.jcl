//LIBMQRUN JOB (ACCT),'RUN LIBMQTST',
//         CLASS=A,MSGCLASS=X,NOTIFY=&SYSUID
//*-------------------------------------------------------------*
//*  IBM Z Xplore placeholder job to run MQ+DB2 test LIBMQTST   *
//*  Replace &HLQ, &COBLOAD, &MQLOAD, &DB2LOAD with real values:*
//*    - &HLQ      : your HLQ (e.g. Z12345)                     *
//*    - &COBLOAD  : COBOL loadlib with LIBMQTST (e.g. &HLQ..LIB.LOAD) *
//*    - &MQLOAD   : IBM MQ loadlib (e.g. CSQ900.SCSQLOAD)      *
//*    - &DB2LOAD  : DB2 SDSNLOAD for runtime (e.g. SDSN.SDSNLOAD) *
//*-------------------------------------------------------------*
//SET HLQ=Z12345
//SET COBLOAD=&HLQ..LIB.LOAD
//SET MQLOAD=CSQ900.SCSQLOAD
//SET DB2LOAD=SDSN.SDSNLOAD
//*
//RUN     EXEC PGM=LIBMQTST,REGION=0M
//STEPLIB DD  DSN=&COBLOAD,DISP=SHR
//        DD  DSN=&MQLOAD,DISP=SHR
//        DD  DSN=&DB2LOAD,DISP=SHR
//SYSOUT  DD  SYSOUT=*
//*
