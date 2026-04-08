//CICS4ZXP JOB FB3
// EXPORT SYMLIST=(*)
// SET TSOUID=&SYSUID
//*====================================================================*
//*        DELETE AND DEFINE TEMPORARY DATA SETS                       *
//*====================================================================*
//DELLOGS  EXEC PGM=IXCMIAPU
//SYSPRINT  DD SYSOUT=*
//SYSOUT    DD SYSOUT=*
//SYSIN     DD *,SYMBOLS=EXECSYS
  DATA TYPE(LOGR) REPORT(NO)
    DELETE LOGSTREAM NAME(&TSOUID..LOG.DFHLGLOG)
    DELETE LOGSTREAM NAME(&TSOUID..LOG.DFHSHUNT)
    DELETE LOGSTREAM NAME(&TSOUID..LOG.DFHLOG)
    DELETE LOGSTREAM NAME(&TSOUID..LOG.DFHJ01)
/*
//*
//*====================================================================*
//*        DELETE TEMP, QUEUE DUMP AND TRACE DATASETS                 *
//*====================================================================*
//DELDSNS  EXEC PGM=IDCAMS,REGION=1M
//SYSPRINT  DD DUMMY
//SYSIN     DD *,SYMBOLS=EXECSYS
  DELETE &TSOUID..CICS.DFHTEMP
  DELETE &TSOUID..CICS.DFHINTRA
  DELETE &TSOUID..CICS.DFHLRQ
  SET MAXCC=0
/*
//*
//*====================================================================*
//*        DEFINE DATASETS AND LOGSTREAMS FOR REGION LOGGER           *
//*====================================================================*
//*DEFLOGS  EXEC PGM=IXCMIAPU
//*SYSPRINT  DD SYSOUT=*
//*SYSOUT    DD SYSOUT=*
//*SYSIN     DD *,SYMBOLS=EXECSYS
//* DATA TYPE(LOGR) REPORT(NO)
//*   DEFINE LOGSTREAM NAME(&TSOUID..LOG.DFHLGLOG)
//*          EHLQ(&TSOUID..CICS)
//*          DASDONLY(YES)
//*          MAXBUFSIZE(64000)
//*          LS_SIZE(3000)
//*          STG_SIZE(3000)
//*          LOWOFFLOAD(40) HIGHOFFLOAD(80)
//*   DEFINE LOGSTREAM NAME(&TSOUID..LOG.DFHSHUNT)
//*          EHLQ(&TSOUID..CICS)
//*          DASDONLY(YES)
//*          MAXBUFSIZE(64000)
//*          LS_SIZE(3000)
//*          STG_SIZE(3000)
//*          LOWOFFLOAD(40) HIGHOFFLOAD(80)
//*   DEFINE LOGSTREAM NAME(&TSOUID..LOG.DFHLOG)
//*          EHLQ(&TSOUID..CICS)
//*          DASDONLY(YES)
//*          MAXBUFSIZE(64000)
//*          LS_SIZE(3000)
//*          STG_SIZE(3000)
//*          LOWOFFLOAD(40) HIGHOFFLOAD(80)
//*   DEFINE LOGSTREAM NAME(&TSOUID..LOG.DFHJ01)
//*          EHLQ(&TSOUID..CICS)
//*          DASDONLY(YES)
//*          MAXBUFSIZE(64000)
//*          LS_SIZE(3000)
//*          STG_SIZE(3000)
//*          LOWOFFLOAD(40) HIGHOFFLOAD(80)
//*
//*
//*====================================================================*
//*        DEFINE DATASETS FOR TEMP AND QUEUE SPACE                   *
//*====================================================================*
//DEFDSNS  EXEC PGM=IDCAMS,REGION=1M
//SYSPRINT  DD DUMMY
//SYSIN     DD *,SYMBOLS=EXECSYS
  DEFINE CLUSTER(NAME(&TSOUID..CICS.DFHTEMP)-
           RECORDSIZE(4089,4089)-
           REC(200)-
           NIXD -
           CISZ(4096)-
           VOLUME(ZXPC02) SHR(2 3)) -
         DATA(NAME(&TSOUID..CICS.DFHTEMP.DATA)-
           UNIQUE)
  DEFINE CLUSTER(NAME(&TSOUID..CICS.DFHINTRA)-
           RECORDSIZE(4089,4089)-
           REC(100)-
           NIXD -
           CISZ(4096)-
           VOLUME(ZXPC02) SHR(2 3)) -
         DATA(NAME(&TSOUID..CICS.DFHINTRA.DATA)-
           UNIQUE)
  DEFINE CLUSTER(NAME(&TSOUID..CICS.DFHLRQ)-
           INDEXED-
           LOG(UNDO)-
           CYL(2 1)-
           VOLUME(ZXPC02)-
           RECORDSIZE( 2232 2400 )-
           KEYS( 40 0 )-
           FREESPACE ( 0 10 )-
           SHAREOPTIONS( 2 3 ))-
         DATA (NAME(&TSOUID..CICS.DFHLRQ.DATA) -
           CISZ(2560)) -
         INDEX (NAME(&TSOUID..CICS.DFHLRQ.INDEX))
/*
//*
//*====================================================================*
//*        SET RETURN CODE TO CONTROL IF CICS SHOULD BE STARTED       *
//*====================================================================*
//CICSCNTL EXEC PGM=IDCAMS,REGION=1M
//SYSPRINT  DD DUMMY
//SYSIN     DD DISP=SHR,DSN=DFH620.SYSIN(DFHRCYES)
//*
//*====================================================================*
//*        SET RETURN CODE TO CONTROL DUMP AND TRACE ANALYSIS STEPS   *
//*====================================================================*
//DTCNTL   EXEC PGM=IDCAMS,REGION=1M
//SYSPRINT  DD DUMMY
//SYSIN     DD DISP=SHR,DSN=DFH620.SYSIN(DFHRCNO)
//*
//*====================================================================*
//*        DEFINE A & B DATASETS FOR TRACE                            *
//*====================================================================*
//DEFTRACE EXEC PGM=IEFBR14
//AUXT      DD DISP=(NEW,PASS),
//             SPACE=(CYL,(1)),
//             BLKSIZE=4096,RECFM=F,LRECL=4096,
//             DSN=&&DFHAUXT
//BUXT      DD DISP=(NEW,PASS),
//             SPACE=(CYL,(1)),
//             BLKSIZE=4096,RECFM=F,LRECL=4096,
//             DSN=&&DFHBUXT
//*
//*====================================================================*
//*        DEFINE A & B DATASETS FOR DUMP                             *
//*====================================================================*
//DEFDUMP EXEC PGM=IEFBR14
//DMPA      DD DISP=(NEW,PASS),
//             SPACE=(CYL,(5)),
//             RECFM=VB,LRECL=4092,BLKSIZE=4096,
//             DSN=&&DFHDMPA
//DMPB      DD DISP=(NEW,PASS),
//             SPACE=(CYL,(5)),
//             RECFM=VB,LRECL=4092,BLKSIZE=4096,
//             DSN=&&DFHDMPB
//*
//*====================================================================*
//*        SET PORTS FOR TCPIPSERVICE(S)                              *
//*====================================================================*
//PORTACQ  EXEC PGM=BPXBATCH,REGION=0M
//STEPLIB   DD DSN=CEE.SCEERUN,DISP=SHR
//STDERR    DD SYSOUT=*
//STDOUT    DD DSN=&&CSDUP,DISP=(NEW,PASS),
//             SPACE=(TRK,1),LRECL=80,RECFM=F,BLKSIZE=80
//STDENV    DD *
_CEE_RUNOPTS=FILETAG(AUTOCVT,AUTOTAG) POSIX(ON)
_BPXK_AUTOCVT=ON
PATH=/z/rocket/tools/bin:/z/bin
PERL5LIB=/usr/lpp/perl/lib/perl5
LIBPATH=/usr/lib:/lib
/*
//STDPARM   DD *,SYMBOLS=EXECSYS
SH /z/bin/cicsport_acquire &TSOUID. DFH\$WUTC
/*
//*
//*====================================================================*
//*        UPDATE CSD WITH PORT ASSIGNMENTS                           *
//*====================================================================*
//CSDUP    EXEC PGM=DFHCSDUP,REGION=1M
//STEPLIB   DD DSN=DFH620.CICS.SDFHLOAD,DISP=SHR
//DFHCSD    DD DSN=&TSOUID..CICS.DFHCSD,DISP=SHR
//SYSPRINT  DD SYSOUT=*
//SYSDUMP   DD SYSOUT=*
//SYSIN     DD DSN=&&CSDUP,DISP=(OLD,DELETE)
//*
//*====================================================================*
//*        EXECUTE CICS                                               *
//*====================================================================*
//CICS     EXEC PGM=DFHSIP,REGION=0M,MEMLIMIT=10G,TIME=1,
//             COND=(1,NE,CICSCNTL),PARM='START=INITIAL,SYSIN'
//SYSIN     DD DISP=SHR,DSN=DFH620.SYSIN(DFH$SIPX)
//          DD DISP=SHR,DSN=&TSOUID..CICS.SYSIN(DFH$SIP)
//          DD *,SYMBOLS=EXECSYS
 XTRAN=NO
 GMTEXT='CICS TS 6.2 - WELCOME TO YOUR PERSONAL REGION
 RESTRICTIONS APPLY - SEE ''ZXP.PUBLIC.CICS.README'''
 APPLID=(CX&TSOUID.,CX&TSOUID.)
 .END
/*
//DFHCSD    DD DISP=OLD,DSN=&TSOUID..CICS.DFHCSD
//DFHCMACD  DD DISP=SHR,DSN=DFH620.DFHCMACD
//STEPLIB   DD DISP=SHR,DSN=DFH620.CICS.SDFHAUTH
//          DD DISP=SHR,DSN=DFH620.CICS.SDFHLINK
//          DD DISP=SHR,DSN=DFH620.CPSM.SEYUAUTH
//          DD DISP=SHR,DSN=DFH620.SDFHLIC
//          DD DISP=SHR,DSN=CSQ920.SCSQAUTH
//          DD DISP=SHR,DSN=DSND10.SDSNLOAD
//          DD DISP=SHR,DSN=DSND10.SDSNLOD2
//          DD DISP=SHR,DSN=CEE.SCEERUN2
//          DD DISP=SHR,DSN=CEE.SCEERUN
//DFHTEMP   DD DISP=SHR,DSN=&TSOUID..CICS.DFHTEMP
//DFHINTRA  DD DISP=SHR,DSN=&TSOUID..CICS.DFHINTRA
//DFHLCD    DD DISP=SHR,DSN=&TSOUID..CICS.DFHLCD
//DFHGCD    DD DISP=SHR,DSN=&TSOUID..CICS.DFHGCD
//DFHLRQ    DD DISP=SHR,DSN=&TSOUID..CICS.DFHLRQ
//DFHCXRF   DD SYSOUT=*
//LOGUSR    DD SYSOUT=*,DCB=(DSORG=PS,RECFM=V,BLKSIZE=136)
//MSGUSR    DD SYSOUT=*,DCB=(DSORG=PS,RECFM=V,BLKSIZE=140)
//CEEMSG    DD SYSOUT=*,DCB=(DSORG=PS,RECFM=V,BLKSIZE=165)
//CEEOUT    DD SYSOUT=*,DCB=(DSORG=PS,RECFM=V,BLKSIZE=137)
//DFHAUXT   DD DISP=SHR,DSN=&&DFHAUXT,DCB=BUFNO=5
//DFHBUXT   DD DISP=SHR,DSN=&&DFHBUXT,DCB=BUFNO=5
//DFHDMPA   DD DISP=SHR,DSN=&&DFHDMPA
//DFHDMPB   DD DISP=SHR,DSN=&&DFHDMPB
//SYSABEND  DD SYSOUT=*
//SYSPRINT  DD SYSOUT=*
//PRINTER   DD SYSOUT=*,DCB=BLKSIZE=121
//DFHRPL    DD DSN=DFH620.CPSM.SEYULOAD,DISP=SHR
//          DD DSN=DFH620.CICS.SDFHLOAD,DISP=SHR
//          DD DSN=ZXP.CICS.PROD.DFHLOAD,DISP=SHR
//          DD DSN=CSQ920.SCSQAUTH,DISP=SHR
//          DD DSN=CSQ920.SCSQLOAD,DISP=SHR
//          DD DSN=&TSOUID..CICS.PROD.DFHLOAD,DISP=SHR
//          DD DSN=CEE.SCEECICS,DISP=SHR
//          DD DSN=CEE.SCEERUN2,DISP=SHR
//          DD DSN=CEE.SCEERUN,DISP=SHR
//*
//**********************************************************************
//*        CICS ENDS HERE                                              *
//**********************************************************************
//PRTDMPA EXEC PGM=DFHDU750,PARM=SINGLE,REGION=0M,COND=(1,NE,DTCNTL)
//STEPLIB   DD DISP=SHR,DSN=DFH620.CICS.SDFHLOAD
//DFHTINDX  DD SYSOUT=*
//SYSPRINT  DD SYSOUT=*
//DFHPRINT  DD SYSOUT=*
//DFHDMPDS  DD DISP=SHR,DSN=&&DFHDMPA
//SYSIN     DD DUMMY
//PRTDMPB EXEC PGM=DFHDU750,PARM=SINGLE,REGION=0M,COND=(1,NE,DTCNTL)
//STEPLIB   DD DISP=SHR,DSN=DFH620.CICS.SDFHLOAD
//DFHTINDX  DD SYSOUT=*
//SYSPRINT  DD SYSOUT=*
//DFHPRINT  DD SYSOUT=*
//DFHDMPDS  DD DISP=SHR,DSN=&&DFHDMPB
//SYSIN     DD DUMMY
//PRTAUXT EXEC PGM=DFHTU750,REGION=0M,COND=(1,NE,DTCNTL)
//STEPLIB   DD DISP=SHR,DSN=DFH620.CICS.SDFHLOAD
//DFHAUXT   DD DISP=SHR,DSN=&&DFHAUXT
//DFHAXPRT  DD SYSOUT=*
//DFHAXPRM  DD DUMMY
//PRTBUXT EXEC PGM=DFHTU750,REGION=0M,COND=(1,NE,DTCNTL)
//STEPLIB   DD DISP=SHR,DSN=DFH620.CICS.SDFHLOAD
//DFHAUXT   DD DISP=SHR,DSN=&&DFHBUXT
//DFHAXPRT  DD SYSOUT=*
//DFHAXPRM  DD DUMMY
//*
//*====================================================================*
//*        RELEASE PORTS FOR TCPIP SERVICES                           *
//*====================================================================*
//PORTREL  EXEC PGM=BPXBATCH,REGION=0M,COND=EVEN
//STEPLIB   DD DSN=CEE.SCEERUN,DISP=SHR
//STDERR    DD DUMMY
//STDOUT    DD SYSOUT=*
//STDENV    DD *
_CEE_RUNOPTS=FILETAG(AUTOCVT,AUTOTAG) POSIX(ON)
_BPXK_AUTOCVT=ON
PATH=/z/rocket/tools/bin:/z/bin
PERL5LIB=/usr/lpp/perl/lib/perl5
LIBPATH=/usr/lib:/lib
/*
//STDPARM   DD *,SYMBOLS=EXECSYS
SH /z/bin/cicsport_release &TSOUID.
/*
//DELDSNS2 EXEC PGM=IDCAMS,REGION=1M,COND=EVEN
//SYSPRINT  DD DUMMY
//SYSIN     DD *,SYMBOLS=EXECSYS
  DELETE &TSOUID..CICS.DFHTEMP
  DELETE &TSOUID..CICS.DFHINTRA
  DELETE &TSOUID..CICS.DFHLRQ
  SET MAXCC=0
/*
