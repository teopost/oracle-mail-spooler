create table MAIL_SPOOLER
(
  ID                   number(28)      not null,
  SUBJECT              varchar2(3000)  not null,
  TEXT_MESSAGE_BODY    varchar2(4000)  not null,
  HTML_MESSAGE_BODY    varchar2(4000) ,
  DESTINATION          varchar2(2000)  not null,
  ID_MAILBOX           number(28)      not null,
  DATE_CREATED         date            not null,
  DATE_PROCESSED       date           ,
  STATUS               varchar2(6)     not null,
  ERR_MESSAGE          varchar2(2000) ,
  ERR_NUMBER           varchar2(2000) 
);

alter table MAIL_SPOOLER add constraint MAIL_SPOOLER_PK primary key (ID) 
go

create table MAIL_BOXES
(
  ID                   number(28)      not null,
  EMAIL_SENDER         varchar2(500)   not null,
  HOST_NAME            varchar2(500)   not null,
  OUT_PORT             number(5)       not null
);

alter table MAIL_BOXES add constraint MAIL_BOXES_PK primary key (ID);

alter table MAIL_SPOOLER add constraint MAILBOXESPOO foreign key (ID_MAILBOX) references MAIL_BOXES ;

create sequence SEQ_MAILSPOOLER_ID start with 1 nocache;

create sequence SEQ_MAILBOXES_ID start with 1 nocache;

create procedure MAIL_QUEUE (p_SUBJECT varchar2, p_TEXTBODY varchar2, p_HTMLBODY varchar2, p_DESTINATION varchar2, p_IDMAILBOX number) as
  v_VIDMAILBOXES number(28);
  v_VEMAISENDMAI varchar2(500);
  v_VHOSTMAILBOX varchar2(500);
  v_VOUTPORTMAIL number(5);
  v_FOUND boolean;
BEGIN
  -- 
  -- MAIL QUEUE Body
  -- Corpo Procedura
  -- 
  -- 
  -- Esiste una configurazione per questa mailbox .
  -- 
  declare cursor S0 is
  select
    A.ID as ID,
    A.EMAIL_SENDER as EMAILSENDER,
    A.HOST_NAME as HOST,
    A.OUT_PORT as OUTPORT
  from
    MAIL_BOXES A
  where (A.ID = p_IDMAILBOX)
    ;
  begin open S0;
  fetch S0 into
    v_VIDMAILBOXES,
    v_VEMAISENDMAI,
    v_VHOSTMAILBOX,
    v_VOUTPORTMAIL;
  v_FOUND := S0%FOUND;
  close S0; end;
  if v_FOUND then
    insert into MAIL_SPOOLER
    (
      ID,
      SUBJECT,
      TEXT_MESSAGE_BODY,
      HTML_MESSAGE_BODY,
      DESTINATION,
      ID_MAILBOX,
      DATE_CREATED,
      STATUS
    )
    values
    (
      SEQ_MAILSPOOLER_ID.NextVal,
      p_SUBJECT,
      p_TEXTBODY,
      p_HTMLBODY,
      p_DESTINATION,
      p_IDMAILBOX,
      SYSDATE,
      'Q'
    )
    ;
    COMMIT;
  else
    raise_application_error(-20000-(1),'Mailbox not found');
  end if;
END;
/


create or replace procedure SEND_QUEUE as
  v_SERRORMESSAG varchar2(2000);
  v_SERRORNUMBER varchar2(50);
BEGIN
  -- 
  -- SEND QUEUE Body
  -- Corpo Procedura
  -- 
  declare cursor C2 is
    select
      A.ID as IDMAILSPOOLE,
      A.SUBJECT as SUBJMAILSPOO,
      A.TEXT_MESSAGE_BODY as TEXMESBOMASP,
      A.DESTINATION as DESTMAILSPOO,
      A.ID_MAILBOX as IDMAILMAISPO,
      A.STATUS as STATMAILSPOO,
      B.HOST_NAME as HOSTMAILBOXE,
      B.EMAIL_SENDER as EMAISENDMAIL,
      B.OUT_PORT as OUTPORTMAILB,
      A.DATE_CREATED as DATCREMAISPO,
      A.DATE_PROCESSED as DATPROMAISPO,
      A.HTML_MESSAGE_BODY as HTMMESBOMASP,
      A.ERR_MESSAGE as ERRMESMAISPO,
      A.ERR_NUMBER as ERRNUMMAISPO
    from
      MAIL_SPOOLER A,
      MAIL_BOXES B
    where B.ID = A.ID_MAILBOX
    and   (A.STATUS = 'Q')
    ;
  begin for MAILSPOOLERMAILSPOOLER in C2 loop
    begin
      SEND_MAIL2 (MAILSPOOLERMAILSPOOLER.DESTMAILSPOO,MAILSPOOLERMAILSPOOLER.EMAISENDMAIL,MAILSPOOLERMAILSPOOLER.SUBJMAILSPOO,MAILSPOOLERMAILSPOOLER.TEXMESBOMASP,MAILSPOOLERMAILSPOOLER.HTMMESBOMASP,MAILSPOOLERMAILSPOOLER.HOSTMAILBOXE);
      --SEND_MAIL (MAILSPOOLERMAILSPOOLER.DESTMAILSPOO,MAILSPOOLERMAILSPOOLER.SUBJMAILSPOO,MAILSPOOLERMAILSPOOLER.TEXMESBOMASP,MAILSPOOLERMAILSPOOLER.HOSTMAILBOXE,MAILSPOOLERMAILSPOOLER.EMAISENDMAIL,MAILSPOOLERMAILSPOOLER.OUTPORTMAILB);
      update MAIL_SPOOLER set
        STATUS = 'S',
        DATE_PROCESSED = SYSDATE
      where (ID = MAILSPOOLERMAILSPOOLER.IDMAILSPOOLE)
      ;
      COMMIT;
    exception when others then
      v_SERRORMESSAG := SQLERRM;
      v_SERRORNUMBER := TO_CHAR ( SQLCODE );
      update MAIL_SPOOLER set
        STATUS = 'E',
        DATE_PROCESSED = SYSDATE,
        ERR_NUMBER = MAIL_SPOOLER.ERR_NUMBER,
        ERR_MESSAGE = v_SERRORMESSAG
      where (ID = MAILSPOOLERMAILSPOOLER.IDMAILSPOOLE)
      ;
      COMMIT;
    end;
  end loop; end;
END;
/

