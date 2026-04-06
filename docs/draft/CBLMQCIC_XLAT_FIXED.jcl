//CBLMQCIX JOB 1,NOTIFY=&SYSUID,CLASS=A,MSGCLASS=H,TIME=1440
//*-------------------------------------------------------------------*
//* Compile + Link-edit + Bind (DB2) for CICS COBOL MQ program
//* Target program: LIBMQCIC
//* Variant: external CICS translator DFHECP1$ (no DFHAPIR dependency)
//*-------------------------------------------------------------------*
//*-------------------------------------------------------------------*
//* 1) CICS TRANSLATION (EXEC CICS -> COBOL)
//*-------------------------------------------------------------------*
//TRANSL   EXEC PGM=DFHECP1$,REGION=0M
//STEPLIB  DD  DSN=DFH620.CICS.SDFHLOAD,DISP=SHR
//SYSPRINT DD  SYSOUT=*
//SYSPUNCH DD  DSN=&&CICSTRN,UNIT=SYSALLDA,DISP=(,PASS),
//             SPACE=(CYL,(1,1))
//SYSIN    DD  DISP=SHR,DSN=Z88011.CBL(LIBMQCIC)
//SYSUT1   DD  UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT2   DD  UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//*-------------------------------------------------------------------*
//* 2) COBOL COMPILE + DB2 SQL (translated source as SYSIN)
//*-------------------------------------------------------------------*
//COBOL    EXEC PGM=IGYCRCTL,REGION=0M,PARM='SQL'
//STEPLIB  DD  DSN=IGY640.SIGYCOMP,DISP=SHR
//         DD  DSN=DSND10.DBDG.SDSNEXIT,DISP=SHR
//         DD  DSN=DSND10.SDSNLOAD,DISP=SHR
//         DD  DSN=CEE.SCEERUN,DISP=SHR
//         DD  DSN=CEE.SCEERUN2,DISP=SHR
//SYSIN    DD  DSN=&&CICSTRN,DISP=(OLD,DELETE)
//DBRMLIB  DD  DISP=SHR,DSN=Z88011.DBRMLIB(LIBMQCIC)
//SYSLIB   DD  DSN=CSQ920.SCSQCOBC,DISP=SHR
//         DD  DSN=Z88011.CBL,DISP=SHR
//SYSPRINT DD  SYSOUT=*
//SYSLIN   DD  DSN=&&LOADSET,UNIT=SYSALLDA,
//             DISP=(MOD,PASS),SPACE=(CYL,(1,1))
//SYSUT1   DD  UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT2   DD  UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT3   DD  UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT4   DD  UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT5   DD  UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT6   DD  UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT7   DD  UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT8   DD  UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT9   DD  UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT10  DD  UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT11  DD  UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT12  DD  UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT13  DD  UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT14  DD  UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT15  DD  UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSMDECK DD  UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//*-------------------------------------------------------------------*
//* 3) LINK-EDIT (CICS + DB2 + MQ)
//*-------------------------------------------------------------------*
//LKED     EXEC PGM=IEWBLINK,COND=(8,LT,COBOL),REGION=0M
//SYSLIB   DD  DSN=CEE.SCEELKED,DISP=SHR
//         DD  DSN=DSND10.SDSNLOAD,DISP=SHR
//         DD  DSN=DFH620.CICS.SDFHLOAD,DISP=SHR
//         DD  DSN=CSQ920.SCSQLOAD,DISP=SHR
//SYSPRINT DD  SYSOUT=*
//SYSUT1   DD  UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSLIN   DD  DSN=&&LOADSET,DISP=(OLD,DELETE)
//SYSIN    DD  *
  INCLUDE SYSLIB(DFHELII)
  INCLUDE SYSLIB(CSQCSTUB)
  ENTRY  LIBMQCIC
  NAME   LIBMQCIC(R)
/*
//SYSLMOD  DD  DSN=Z88011.LOAD(LIBMQCIC),DISP=SHR
//*-------------------------------------------------------------------*
//* 4) BIND DB2 PACKAGE (optional PLAN included as comment)
//*-------------------------------------------------------------------*
//BIND     EXEC PGM=IKJEFT01,COND=(8,LT,LKED)
//STEPLIB  DD  DSN=DSND10.DBDG.SDSNEXIT,DISP=SHR
//         DD  DSN=DSND10.SDSNLOAD,DISP=SHR
//DBRMLIB  DD  DSN=Z88011.DBRMLIB(LIBMQCIC),DISP=SHR
//SYSUDUMP DD  DUMMY
//SYSTSPRT DD  SYSOUT=*
//SYSPRINT DD  SYSOUT=*
//SYSTSIN  DD  *,SYMBOLS=EXECSYS
 DSN SYSTEM(DBDG)
 BIND PACKAGE(Z88011) MEMBER(LIBMQCIC) ACT(REP) ISO(CS) ENCODING(EBCDIC)
* Optional (recommended): bind a stable plan and use it at runtime
* BIND PLAN(Z88011) PKLIST(Z88011.*) ACTION(REPLACE) ISO(CS) ENCODING(EBCDIC)
 END
/*