-- come sys

grant execute on UTL_TCP to MAIL_QUEUE;
GRANT EXECUTE ON utl_smtp TO MAIL_QUEUE;


CREATE OR REPLACE PROCEDURE MAIL_QUEUE.send_mail_to (
   p_to          IN VARCHAR2,
   p_from        IN VARCHAR2,
   p_subject     IN VARCHAR2,
   p_cc          IN VARCHAR2 DEFAULT NULL,
   p_bcc         IN VARCHAR2 DEFAULT NULL,
   p_text_msg    IN VARCHAR2 DEFAULT NULL,
   p_html_msg    IN VARCHAR2 DEFAULT NULL,
   p_smtp_host   IN VARCHAR2,
   p_smtp_port   IN NUMBER DEFAULT 25)
AS
   l_mail_conn   UTL_SMTP.connection;
   l_boundary    VARCHAR2 (50) := '----=*#abc1234321cba#*=';
   v_stringa     VARCHAR2 (2000);
   v_giri        NUMBER(9);
   v_inizio      NUMBER(9);
   v_fine        NUMBER(9);
   p_mail     VARCHAR2 (2000);
BEGIN
   l_mail_conn := UTL_SMTP.open_connection (p_smtp_host, p_smtp_port);
   UTL_SMTP.helo (l_mail_conn, p_smtp_host);
   UTL_SMTP.mail (l_mail_conn, p_from);
   
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- 
    --- gestione del multi mail
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- 
    v_stringa := p_to;

    v_stringa := replace(v_stringa, ' ', '');
    v_stringa := replace(v_stringa, ',', ';');
        
    dbms_OUTPUT.PUT_LINE('Stringa = '||v_stringa);
        
    select REGEXP_COUNT(v_stringa, ';') + 1 into v_giri from dual;
        
    --dbms_OUTPUT.PUT_LINE('Giri = '||v_giri);

    v_inizio := 1;

   FOR i IN 1..v_giri LOOP 
      
        v_fine := instr(v_stringa, ';', v_inizio) ;
            
        if v_fine = 0
            then v_fine := length(v_stringa) + 1;
        end if;
            
        --dbms_OUTPUT.PUT_LINE('Processo = '||i||'/'||v_inizio||'/'||v_fine);
            
        p_mail := substr(v_stringa, v_inizio, v_fine - v_inizio);
        
        UTL_SMTP.rcpt (l_mail_conn, p_mail);
               
        --dbms_OUTPUT.PUT_LINE('-'||p_mail||'-');
            
        v_inizio := v_fine + 1;

   END LOOP;
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- 
   


   
   
   
--   --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---  
--   --- destinatario principale
--   UTL_SMTP.rcpt (l_mail_conn, p_to);
--
   --- destinatario per conoscenza 
   IF TRIM (p_cc) IS NOT NULL
   THEN
      UTL_SMTP.rcpt (l_mail_conn, p_cc);
   END IF;

   --- destinatario nascosto 
   IF TRIM (p_bcc) IS NOT NULL
   THEN
      UTL_SMTP.rcpt (l_mail_conn, p_bcc);
   END IF;
--   --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---  

   UTL_SMTP.open_data (l_mail_conn);

   UTL_SMTP.write_data (
      l_mail_conn,
      'Date: ' || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS') || UTL_TCP.crlf);
   UTL_SMTP.write_data (l_mail_conn, 'To: ' || p_to || UTL_TCP.crlf);


   IF TRIM (p_cc) IS NOT NULL
   THEN
      UTL_SMTP.write_data (
         l_mail_conn,
         'CC: ' || REPLACE (p_cc, ',', ';') || UTL_TCP.crlf);
   END IF;

   UTL_SMTP.write_data (l_mail_conn, 'From: ' || p_from || UTL_TCP.crlf);
   UTL_SMTP.write_data (l_mail_conn,
                        'Subject: ' || p_subject || UTL_TCP.crlf);
   UTL_SMTP.write_data (l_mail_conn, 'Reply-To: ' || p_from || UTL_TCP.crlf);
   UTL_SMTP.write_data (l_mail_conn, 'MIME-Version: 1.0' || UTL_TCP.crlf);
   UTL_SMTP.write_data (
      l_mail_conn,
         'Content-Type: multipart/alternative; boundary="'
      || l_boundary
      || '"'
      || UTL_TCP.crlf
      || UTL_TCP.crlf);

   IF p_text_msg IS NOT NULL
   THEN
      UTL_SMTP.write_data (l_mail_conn, '--' || l_boundary || UTL_TCP.crlf);
      UTL_SMTP.write_data (
         l_mail_conn,
            'Content-Type: text/plain; charset="iso-8859-1"'
         || UTL_TCP.crlf
         || UTL_TCP.crlf);

      UTL_SMTP.write_data (l_mail_conn, p_text_msg);
      UTL_SMTP.write_data (l_mail_conn, UTL_TCP.crlf || UTL_TCP.crlf);
   END IF;

   IF p_html_msg IS NOT NULL
   THEN
      UTL_SMTP.write_data (l_mail_conn, '--' || l_boundary || UTL_TCP.crlf);
      UTL_SMTP.write_data (
         l_mail_conn,
            'Content-Type: text/html; charset="iso-8859-1"'
         || UTL_TCP.crlf
         || UTL_TCP.crlf);

      UTL_SMTP.write_data (l_mail_conn, p_html_msg);
      UTL_SMTP.write_data (l_mail_conn, UTL_TCP.crlf || UTL_TCP.crlf);
   END IF;

   UTL_SMTP.write_data (l_mail_conn,
                        '--' || l_boundary || '--' || UTL_TCP.crlf);
   UTL_SMTP.close_data (l_mail_conn);

   UTL_SMTP.quit (l_mail_conn);
END;
/

CREATE OR REPLACE PROCEDURE MAIL_QUEUE.send_queue
AS
   v_sqlerrm        VARCHAR2 (2000);
   v_error_number   VARCHAR2 (50);
BEGIN
   --
   -- SEND QUEUE Body
   -- Corpo Procedura
   --

   --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- 
   --- Recupero le mail da spedire
   --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- 
      
   DECLARE
      CURSOR c2
      IS
         SELECT a.id AS id,
                a.subject AS subject,
                a.text_message_body AS text_message_body,
                a.destination AS destination,
                a.destination_cc AS destination_cc,
                a.destination_bcc AS destination_bcc,
                a.id_mailbox AS id_mailbox,
                a.status AS status,
                b.host_name AS host_name,
                b.email_sender AS email_sender,
                b.out_port AS out_port,
                a.date_created AS date_created,
                a.date_processed AS date_processed,
                a.html_message_body AS html_message_body,
                a.err_message AS err_message,
                a.err_number AS err_number
           FROM mail_spooler a, mail_boxes b
          WHERE b.id = a.id_mailbox AND (a.status = 'Q');

          
   BEGIN
      FOR rec_mail IN c2
      LOOP
         BEGIN
         
            --- spedizione delle mail 
            send_mail_to (rec_mail.destination,
                          rec_mail.email_sender,
                          rec_mail.subject,
                          rec_mail.destination_cc,
                          rec_mail.destination_bcc,
                          rec_mail.text_message_body,
                          rec_mail.html_message_body,
                          rec_mail.host_name);
            
            --- aggiornamento della tabella di spool
            UPDATE mail_spooler
               SET status = 'S', date_processed = SYSDATE
             WHERE (id = rec_mail.id);

            COMMIT;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_sqlerrm := SQLERRM;
               v_error_number := TO_CHAR (SQLCODE);

               --- in caso di errore segno la riga
               UPDATE mail_spooler
                  SET status = 'E',
                      date_processed = SYSDATE,
                      err_number = mail_spooler.err_number,
                      err_message = v_sqlerrm
                WHERE (id = rec_mail.id);

               COMMIT;
         END;
      END LOOP;
   END;
END;
/

CREATE OR REPLACE procedure MAIL_QUEUE.mail_queue (p_subject            varchar2,
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

