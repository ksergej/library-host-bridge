//LIBSCHEMA JOB (ACCT),'CREATE LIB SCHEMA',
//         CLASS=A,MSGCLASS=X,NOTIFY=&SYSUID
//*-------------------------------------------------------------*
//* IBM Z Xplore placeholder job to create LIBRARY schema via   *
//* DSNTEP2. Replace placeholders:                              *
//*   - &DB2LOAD : DB2 SDSNLOAD (e.g. SDSN.SDSNLOAD)            *
//*   - SYSIN    : source SQL (from host-library-infra/db2/schema.sql) *
//*-------------------------------------------------------------*
//SET DB2LOAD=SDSN.SDSNLOAD
//STEP1   EXEC PGM=IKJEFT01,REGION=0M
//SYSTSPRT DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//SYSTSIN  DD *
  DSN SYSTEM(DB2A)
  RUN PROGRAM(DSNTEP2) PLAN(DSNTEP2) -
      LIB('&DB2LOAD')
  END
/* 
//SYSIN    DD DSN=&SYSUID..SQL(SCHEMA),DISP=SHR
/*
