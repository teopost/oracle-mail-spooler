CREATE OR REPLACE PROCEDURE MAIL_QUEUE.SEND_MAIL (destination in varchar2, subject in varchar2, message_body in varchar2, mailhost in varchar2, sender in varchar2, Port in number) 
 is
    mail_conn   utl_smtp.connection;
    r           utl_smtp.replies;
BEGIN
    mail_conn := utl_smtp.open_connection(mailhost, Port);
    r:=utl_smtp.ehlo(mail_conn, mailhost);
    for i in r.first..r.last loop
       dbms_output.put_line('helo code='||r(i).code||' text='||r(i).text);
    end loop;
    utl_smtp.mail(mail_conn, sender);
    utl_smtp.rcpt(mail_conn, destination);
    utl_smtp.open_data(mail_conn);
    utl_smtp.write_data(mail_conn, 'From: '||sender||chr(13)|| CHR(10));
    utl_smtp.write_data(mail_conn, 'Subject: '||subject||chr(13)|| CHR(10));
    utl_smtp.write_data(mail_conn, 'To: '||destination||chr(13)|| CHR(10));
    utl_smtp.write_data(mail_conn, chr(13)|| CHR(10));
    utl_smtp.write_data(mail_conn, message_body||chr(13)|| CHR(10));
    utl_smtp.close_data(mail_conn);
    utl_smtp.quit(mail_conn);
END;
/
