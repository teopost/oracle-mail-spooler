CREATE OR REPLACE PROCEDURE mail_queue.send_mail_to (
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
BEGIN
   l_mail_conn := UTL_SMTP.open_connection (p_smtp_host, p_smtp_port);
   UTL_SMTP.helo (l_mail_conn, p_smtp_host);
   UTL_SMTP.mail (l_mail_conn, p_from);
   
   --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---  
   --- destinatario principale
   UTL_SMTP.rcpt (l_mail_conn, p_to);

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
   --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---  

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
