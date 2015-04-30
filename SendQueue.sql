CREATE OR REPLACE PROCEDURE mail_queue.send_queue
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
