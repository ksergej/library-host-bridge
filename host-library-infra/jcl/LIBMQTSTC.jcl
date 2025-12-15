//LIBMQC   JOB (ACCT),'COBOL MQ COMPILE',
//         CLASS=A,MSGCLASS=X,NOTIFY=&SYSUID
//*-------------------------------------------------------------*
//*  Compile/precompile LIBMQTST (MQ + DB2)
//*  Customize placeholders before use:
//*    &HLQ      : your HLQ (e.g. Z12345)
//*    &COBSRC   : COBOL source PDS with LIBMQTST.cbl and LIBLOAN.cpy
//*    &LOAD     : target load PDS/PDSE (e.g. &HLQ..LOAD)
//*    &DB2LOAD  : DB2 SDSNLOAD (e.g. SDSN.SDSNLOAD)
//*    &MQLOAD   : IBM MQ loadlib (e.g. CSQ900.SCSQLOAD)
//*    &DBRMLIB  : DBRM PDS (e.g. &HLQ..DBRM)
//*  Plan/bind is not shown here; bind LIBMQTST separately.
//*-------------------------------------------------------------*
//PRECOMP EXEC PGM=DSNHPC,REGION=0M,
//         PARM=('HOST(IBMCOB)','APOST','LINECOUNT(60)')
//STEPLIB DD  DSN=&DB2LOAD,DISP=SHR
//SYSIN   DD  DSN=&COBSRC(LIBMQTST),DISP=SHR
//SYSCIN  DD  DSN=&&COBSRC,UNIT=SYSDA,SPACE=(TRK,(5,5)),
//             DISP=(MOD,PASS)
//SYSPUNCH DD DSN=&&DBRM,UNIT=SYSDA,SPACE=(TRK,(5,5)),
//             DISP=(MOD,PASS)
//DBRMLIB DD  DSN=&DBRMLIB(LIBMQTST),DISP=SHR
//SYSPRINT DD SYSOUT=*
//*
//COBOL   EXEC PGM=IGYCRCTL,REGION=0M,COND=(0,LT),
//         PARM='LIB'
//STEPLIB DD  DSN=YOUR.COBOL.COMPILER.LOADLIB,DISP=SHR
//SYSIN   DD  DSN=&&COBSRC,DISP=(OLD,DELETE)
//SYSLIB  DD  DSN=&COBSRC,DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSOUT  DD SYSOUT=*
//SYSLIN  DD DSN=&&OBJ,UNIT=SYSDA,SPACE=(TRK,(5,5)),
//            DISP=(MOD,PASS)
//*
//LKED    EXEC PGM=HEWL,REGION=0M,COND=(0,LT)
//SYSLMOD DD DSN=&LOAD(LIBMQTST),DISP=SHR
//SYSLIN  DD DSN=&&OBJ,DISP=(OLD,DELETE)
//SYSLIB  DD DSN=&MQLOAD,DISP=SHR
//        DD DSN=&DB2LOAD,DISP=SHR
//SYSPRINT DD SYSOUT=*
