create table MAIL_SPOOLER
(
  ID                   number(28)      not null,
  SUBJECT              varchar2(3000)  not null,
  TEXT_MESSAGE_BODY    varchar2(4000)  not null,
  HTML_MESSAGE_BODY    varchar2(4000) ,
  DESTINATION          varchar2(2000)  not null,
  DESTINATION_CC       varchar2(2000)  not null,
  DESTINATION_BCC      varchar2(2000)  not null,
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

/* Formatted on 30/04/2015 17:07:58 (QP5 v5.269.14213.34769) */
create or replace procedure mail_queue (p_subject            varchar2,
                                        p_textbody           varchar2,
                                        p_htmlbody           varchar2,
                                        p_destination        varchar2,
                                        p_destination_cc     varchar2,
                                        p_destination_bcc    varchar2,
                                        p_idmailbox          number)
as
   v_vidmailboxes   number (28);
   v_vemaisendmai   varchar2 (500);
   v_vhostmailbox   varchar2 (500);
   v_voutportmail   number (5);
   v_found          boolean;
begin
   --
   -- MAIL QUEUE Body
   -- Corpo Procedura
   --

   --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- 
   -- Esiste una configurazione per questa mailbox .
   --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- 
   declare
      cursor s0
      is
         select a.id as id,
                a.email_sender as emailsender,
                a.host_name as host,
                a.out_port as outport
           from mail_boxes a
          where (a.id = p_idmailbox);
   begin
      open s0;

      fetch s0
         into v_vidmailboxes,
              v_vemaisendmai,
              v_vhostmailbox,
              v_voutportmail;

      v_found := s0%found;

      close s0;
   end;

   if v_found
   then
      
      --- caricamento della tabella di spool        
      insert into mail_spooler (id,
                                subject,
                                text_message_body,
                                html_message_body,
                                destination,
                                destination_cc,
                                destination_bcc,
                                id_mailbox,
                                date_created,
                                status)
           values (seq_mailspooler_id.nextval,
                   p_subject,
                   p_textbody,
                   p_htmlbody,
                   p_destination,
                   p_destination_cc,
                   p_destination_bcc,
                   p_idmailbox,
                   sysdate,
                   'Q');

      commit;
   else
      raise_application_error (-20000 - (1), 'Mailbox not found');
   end if;
end;
/

