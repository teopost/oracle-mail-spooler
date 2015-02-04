# Oracle Mail Spooler
---
Semplice implementazione per inviare mail da una istanza Oracle (fatta in 3 ore)

Oggetti
---

Tabelle
===

| Tabella | Descrizione |
|---------|-------------|
| MAIL_BOXES | Contiene la configurazione degli account con cui mandare le mail |
| MAIL_SPOOLER | Contiene la coda di messaggi da inviare |

Procedure
===

| Procedura  | Descrizione |
|------------|-------------|
| MAIL_QUEUE | Procedura da usare per mettere in coda le mail da inviare |
| SEND_MAIL  | Procedura che effettua l'invio della mail | 
| SEND_QUEUE | Procedura da schedulare che verifica sulla tabella MAIL_SPOOLER l'esistenza di massaggi da spedire (Statu = Q) e se esistono chiama la SEND_MAIL per l'invio. |

Grants
===
Ho dato agli oggetti MAIL_QUEUE e MAIL_SPOOLER i grant per poter rispettivamente:
1. Mettere in coda i messaggi per la spedizione
2. Leggere i messaggi

Utilizzo
---


Limitazioni
---
Non possono essere inviati messaggi a piu' destinatari.
Attualmente i messaggi non possono superare i 4000 caratteri (faccilmente risolvibile)

Note
--
Per poter effettuare chiamate http, smtp, ssh, ecc direttamente da una istanza oracle bisogna, per questioni di sicurezza, attivare specifiche ACL.
Per fare questo ho :


Per poter utilizzare 

-- 
Stefano Teodorani
Responsabile DB e Sistemi
 
Apex-net Srl
Via Cerchia di S. Giorgio, 145
47521 CESENA (FC)         
Telefono: +39 0547 1902799
Fax: +39 0547 1902060
 

http://www.apexnet.it
http://www.facebook.com/apexnetsrl
s.teodorani@apexnet.it
Interno: +39 0547 1902762
Mobile: +39  348 2902396
