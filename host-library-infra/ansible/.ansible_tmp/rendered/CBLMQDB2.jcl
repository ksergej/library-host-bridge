//CBLMQDB2 JOB 1,NOTIFY=&SYSUID,CLASS=A,MSGCLASS=H,TIME=1440
//********************************************************************
//* Compile + Link-edit + Bind (DB2) for COBOL MQ program
//* This is the canonical "compile+link+bind" job used by Ansible.
//* Variables are injected by Ansible/Jinja2 (no hardcoded DSNs here).
//********************************************************************
//********************************************************************
//*  COMPILE - COBOL + embedded SQL                                  *
//********************************************************************
//COBOL    EXEC PGM=IGYCRCTL,REGION=0M,PARM='SQL'
//STEPLIB  DD  DSN=IGY640.SIGYCOMP,DISP=SHR
//         DD  DSN=DSND10.DBDG.SDSNEXIT,DISP=SHR
//         DD  DSN=DSND10.SDSNLOAD,DISP=SHR
//         DD  DSN=CEE.SCEERUN,DISP=SHR
//         DD  DSN=CEE.SCEERUN2,DISP=SHR
//SYSIN    DD  DISP=SHR,DSN=Z88011.CBL(LIBMQTST)
//DBRMLIB  DD  DISP=SHR,DSN=Z88011.DBRMLIB(LIBMQTST)
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
//********************************************************************
//*  LINK-EDIT                                                      *
//********************************************************************
//LKED     EXEC PGM=IEWBLINK,COND=(8,LT,COBOL),REGION=0M
//SYSLIB   DD  DSN=CEE.SCEELKED,DISP=SHR
//         DD  DSN=DSND10.SDSNLOAD,DISP=SHR
//         DD  DSN=CSQ920.SCSQLOAD,DISP=SHR
//SYSPRINT DD  SYSOUT=*
//SYSUT1   DD  UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSLIN   DD  DSN=&&LOADSET,DISP=(OLD,DELETE)
//         DD  *
  INCLUDE SYSLIB(CSQBSTUB)
  ENTRY  LIBMQTST
  NAME   LIBMQTST(R)
/*
//SYSLMOD  DD  DSN=Z88011.LOAD(LIBMQTST),DISP=SHR
//********************************************************************
//*  BIND DB2 PLAN                                                  *
//********************************************************************
//BIND     EXEC PGM=IKJEFT01,COND=(8,LT,LKED)
//STEPLIB  DD  DSN=DSND10.SDSNLOAD,DISP=SHR
//DBRMLIB  DD  DSN=Z88011.DBRMLIB,DISP=SHR
//SYSUDUMP DD  DUMMY
//SYSTSPRT DD  SYSOUT=*
//SYSPRINT DD  SYSOUT=*
//SYSTSIN  DD  *,SYMBOLS=EXECSYS
 DSN SYSTEM(DBDG)
 BIND PLAN(Z88011) PKLIST(Z88011.*) -
      MEMBER(LIBMQTST) -
      ACT(REP) ISO(CS) ENCODING(EBCDIC)
/*
