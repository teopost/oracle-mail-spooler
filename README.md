# Oracle Mail Spooler

Semplice implementazione per inviare mail da una istanza Oracle

Tabelle
---

| Tabella | Descrizione |
|---------|-------------|
| MAIL_BOXES | Contiene la configurazione degli account con cui mandare le mail |
| MAIL_SPOOLER | Contiene la coda di messaggi da inviare |

Procedure
---

| Procedura  | Descrizione |
|------------|-------------|
| MAIL_QUEUE | Procedura da usare per mettere in coda le mail da inviare |
| SEND_MAIL  | Procedura che effettua l'invio della mail | 
| SEND_QUEUE | Procedura da schedulare che verifica sulla tabella MAIL_SPOOLER l'esistenza di massaggi da spedire (Statu = Q) e se esistono chiama la SEND_MAIL per l'invio. |

Grants
---
Tutti gli oggetti per l'invio delle mail sono creati in uno schema specifico (nel caso descritto chiamao MAIL_QUEUE).
Per utilizzare la procedure che mette in coda i messaggi e per consultare la lista dei messaggi in coda, occorre dare i seguenti grant:

```sql
SQL> grant execute on MAIL_QUEUE to MYUSER;
SQL> grant all on MAIL_SPOOLER to MYUSER;
```

Utilizzo
---
Collegarsi al proprio utente oracle.
Al primo utilizzo è consigliabile creare 2 sinomini per accedere piu' facilmente agli oggetti:

```sql
create synonym MAIL_QUEUE for mail_queue.MAIL_QUEUE;
create synonym MAIL_SPOOLER for mail_queue.MAIL_SPOOLER;
```

Limitazioni
---
- Non possono essere inviati messaggi a piu' destinatari.
- Attualmente il corpo dei messaggi non può superare i 4000 caratteri (facilmente risolvibile)
- Non possono essere inviati allegati

Note
--
Per poter effettuare chiamate http, smtp, ssh, ecc direttamente da una istanza oracle bisogna, per questioni di sicurezza, attivare specifiche ACL.
Per fare questo mi sono collegato con l'utente system e ho creato una specifica ACL, quindi:

1. Creo una ACL per il mio utente MAIL_QUEUE

```sql
BEGIN
  DBMS_NETWORK_ACL_ADMIN.create_acl (
    acl          => 'mail_queue.xml', 
    description  => 'Acl per invio mail da utente MAIL_QUEUE',
    principal    => 'MAIL_QUEUE',
    is_grant     => TRUE, 
    privilege    => 'connect');
    
  COMMIT;
END;
/
```

2. Aggiungo alla ACL la possibilita di aprire una connessione sulla porta 25 per il mio host smtp

```sql
BEGIN
  DBMS_NETWORK_ACL_ADMIN.assign_acl (
    acl => 'mail_queue.xml',
    host => 'smtp.universita.it', 
    lower_port => 25,
    upper_port => NULL); 
  COMMIT;
END;
/
```

3. Controllo che l'ACL sia stata creata
```sql
select * from dba_network_acls
```

Riferimenti
---
- http://remidian.com/2013/01/email-network-access-in-oracle-11g-network-access-control-list-acl/
