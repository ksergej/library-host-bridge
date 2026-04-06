//CBLMQCIC JOB 1,NOTIFY=&SYSUID,CLASS=A,MSGCLASS=H,TIME=1440
//********************************************************************
//* Compile + Link-edit + Bind (DB2) for CICS COBOL MQ program
//* Target program: LIBMQCIC  (CICS + DB2 SQL + MQI)
//*
//* Notes:
//*  - Make sure the FIRST line of LIBMQCIC source contains:
//*        CBL CICS SQL
//*    (or at least: CBL CICS)
//*  - Link-edit uses CICS stub DFHELII and MQ CICS stub CSQCSTUB
//*  - Reply MQ Correlation is handled in program logic
//********************************************************************
//********************************************************************
//*  COMPILE - COBOL + embedded SQL + CICS translation                *
//********************************************************************
//COBOL    EXEC PGM=IGYCRCTL,REGION=0M,PARM='SQL'
//STEPLIB  DD  DSN=IGY640.SIGYCOMP,DISP=SHR
//         DD  DSN=DSND10.DBDG.SDSNEXIT,DISP=SHR
//         DD  DSN=DSND10.SDSNLOAD,DISP=SHR
//         DD  DSN=CEE.SCEERUN,DISP=SHR
//         DD  DSN=CEE.SCEERUN2,DISP=SHR
//* CICS loadlib (for integrated translator / CICS support)
//         DD  DSN=DFH620.CICS.SDFHLOAD,DISP=SHR
//SYSIN    DD  DISP=SHR,DSN=Z88011.CBL(LIBMQCIC)
//DBRMLIB  DD  DISP=SHR,DSN=Z88011.DBRMLIB(LIBMQCIC)
//SYSLIB   DD  DSN=CSQ920.SCSQCOBC,DISP=SHR
//         DD  DSN=Z88011.CBL,DISP=SHR
//* Optional: CICS copybook library if you have it (site-specific)
//*        DD  DSN=DFH620.CICS.SDFHCOB,DISP=SHR
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
//********************************************************************
//*  LINK-EDIT (CICS + DB2 + MQ)                                     *
//********************************************************************
//LKED     EXEC PGM=IEWBLINK,COND=(8,LT,COBOL),REGION=0M
//SYSLIB   DD  DSN=CEE.SCEELKED,DISP=SHR
//         DD  DSN=DSND10.SDSNLOAD,DISP=SHR
//* CICS loadlib contains DFHELII (CICS stub)
//         DD  DSN=DFH620.CICS.SDFHLOAD,DISP=SHR
//* MQ loadlib contains CSQCSTUB (MQ stub for CICS)
//         DD  DSN=CSQ920.SCSQLOAD,DISP=SHR
//SYSPRINT DD  SYSOUT=*
//SYSUT1   DD  UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSLIN   DD  DSN=&&LOADSET,DISP=(OLD,DELETE)
//         DD  *
  INCLUDE SYSLIB(DFHELII)
  INCLUDE SYSLIB(CSQCSTUB)
  ENTRY  LIBMQCIC
  NAME   LIBMQCIC(R)
/*
//SYSLMOD  DD  DSN=Z88011.LOAD(LIBMQCIC),DISP=SHR
//********************************************************************
//*  BIND DB2 PACKAGE (and optionally PLAN)                          *
//********************************************************************
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
* Optional (recommended): bind a stable plan and use it in runtime JCL
* BIND PLAN(Z88011) PKLIST(Z88011.*) ACTION(REPLACE) ISO(CS) ENCODING(EBCDIC)
 END
/*
//********************************************************************
//* End
//********************************************************************
