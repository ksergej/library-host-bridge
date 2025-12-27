CREATE TABLE USERS (
    USER_ID_NUM   BIGINT       GENERATED ALWAYS AS IDENTITY
                  (START WITH 1, INCREMENT BY 1),
    USER_ID       CHAR(10)     NOT NULL,
    NAME          VARCHAR(100) NOT NULL,
    REGISTERED_AT TIMESTAMP    NOT NULL WITH DEFAULT ,
    CONSTRAINT PK_USER PRIMARY KEY (USER_ID_NUM),
    CONSTRAINT UQ_USER_ID UNIQUE (USER_ID)
)
in {{ db2.tablespace }}
;

  CREATE UNIQUE INDEX USERS_I1
                   ON USERS (USER_ID_NUM  ASC) 
                   USING STOGROUP ZXPUSER  PRIQTY 12 ERASE NO 
                   BUFFERPOOL BP0 CLOSE NO;                           
  CREATE UNIQUE INDEX USERS_I2
                   ON USERS (USER_ID  ASC) 
                   USING STOGROUP ZXPUSER  PRIQTY 12 ERASE NO 
                   BUFFERPOOL BP0 CLOSE NO;                           


CREATE TABLE BOOK (
    BOOK_ID_NUM   BIGINT        GENERATED ALWAYS AS IDENTITY
                  (START WITH 1, INCREMENT BY 1),
    BOOK_ID       CHAR(10)      NOT NULL,
    TITLE         VARCHAR(200)  NOT NULL,
    AUTHOR        VARCHAR(200),
    STATUS        CHAR(1)       NOT NULL DEFAULT 'A',
    CONSTRAINT PK_BOOK PRIMARY KEY (BOOK_ID_NUM),
    CONSTRAINT UQ_BOOK_ID UNIQUE (BOOK_ID)
)
in {{ db2.tablespace }}
;

  CREATE UNIQUE INDEX BOOK_I1
                   ON BOOK (BOOK_ID_NUM  ASC) 
                   USING STOGROUP ZXPUSER  PRIQTY 12 ERASE NO 
                   BUFFERPOOL BP0 CLOSE NO;                           
  CREATE UNIQUE INDEX BOOK_I2
                   ON BOOK (BOOK_ID  ASC) 
                   USING STOGROUP ZXPUSER  PRIQTY 12 ERASE NO 
                   BUFFERPOOL BP0 CLOSE NO;                           

CREATE TABLE LOAN (
    LOAN_ID_NUM   BIGINT       GENERATED ALWAYS AS IDENTITY
                  (START WITH 1, INCREMENT BY 1),
    USER_ID       CHAR(10)     NOT NULL,
    BOOK_ID       CHAR(10)     NOT NULL,
    LOAN_DATE     DATE         NOT NULL,
    DUE_DATE      DATE         NOT NULL,
    RETURN_DATE   DATE,
    CONSTRAINT PK_LOAN PRIMARY KEY (LOAN_ID_NUM)
)
in {{ db2.tablespace }}
;

CREATE UNIQUE INDEX LOAN_I1
                   ON LOAN (LOAN_ID_NUM  ASC) 
                   USING STOGROUP ZXPUSER  PRIQTY 12 ERASE NO 
                   BUFFERPOOL BP0 CLOSE NO;                           



commit;
