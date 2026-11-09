# Pulizia periodica su Windows

Il target `cleanup-expired-data:run` richiama esclusivamente la funzione
`cleanExpiredData()` del repository. Non esegue report, PostHog, Discord o OpenAI.

## Configurazione

- Usare un checkout con dipendenze installate e client Prisma generato per il DB
  utilizzato, come per l'applicazione. Node e Bun devono essere disponibili anche
  per l'account che esegue l'attività.
- La connessione viene caricata dal `.env` alla radice del repository.
  Le variabili già presenti nell'ambiente hanno precedenza.
- Se `DATABASE_URL_REPLICA` manca, il job utilizza `DATABASE_URL` anche per le
  letture di replica. Il fallback vale soltanto nel processo del job.
- Il target non usa la cache Nx. Non eseguire manualmente il job mentre è già
  in corso una pulizia pianificata.

## Verifica senza cancellazioni

Dalla radice del repository:

```powershell
bunx nx run cleanup-expired-data:run --check
```

Il controllo verifica il caricamento dell'ambiente e la presenza della connessione;
non importa Prisma, non si collega al database e non verifica le credenziali.
Per verificare anche lo script Windows e la creazione dei log:

```powershell
powershell.exe -NoProfile -File .\jobs\cleanup-expired-data\run.ps1 -Check
```

## Registrazione dell'attività

Eseguire sul server Windows dalla directory dell'installazione. Per funzionare
anche senza una sessione Windows aperta, usare un account autorizzato al logon
batch, con accesso alla rete, al repository, a Bun/Node e al database:

```powershell
.\jobs\cleanup-expired-data\register-task.ps1 -Credential (Get-Credential)
```

La password è affidata a Utilità di pianificazione, non salvata nel repository.
In alternativa, omettere `-Credential`: l'attività funzionerà solo quando l'utente
che la registra è connesso. La registrazione può richiedere una shell elevata a
seconda dell'account e delle policy del server.

La pianificazione è giornaliera alle **05:30 UTC**, con prima esecuzione domani.
In Italia corrisponde alle 06:30 in inverno e alle 07:30 in estate.
La registrazione non avvia cancellazioni. Il task impedisce istanze sovrapposte,
recupera un'esecuzione persa quando possibile e ha un limite di durata di 12 ore.
Un'attività con lo stesso nome non viene sovrascritta.

Il nome predefinito è `Typebot - Cleanup expired data`. Se era già stata
registrata la precedente attività `Typebot expired data cleanup`, rimuoverla
prima di registrare questa versione, per evitare esecuzioni duplicate.

## Esecuzione effettiva e log

**Il seguente comando cancella dati**, usando la funzione installata:

```powershell
powershell.exe -NoProfile -File .\jobs\cleanup-expired-data\run.ps1
```

I log standard ed errori sono separati in `logs/jobs/cleanup-expired-data/`,
esclusa da Git.
Non è prevista rotazione automatica: applicare la politica di conservazione del
server. L'esito è disponibile anche in Utilità di pianificazione (0 = successo).
Il controllo `--check` ha anch'esso esito 0, ma non effettua pulizia.

## Dati eliminati e aggiornamenti

Sul branch attuale la funzione elimina:

- `ChatSession` con `updatedAt` fino alla mezzanotte locale di due giorni prima;
- `Session` e `VerificationToken` con `expires` fino alla mezzanotte locale di
  tre giorni prima.

La pulizia è globale, non limitata a un bot o workspace. Per le chat non controlla
il completamento o l'attesa di webhook: una chat inattiva eliminata non può essere
ripresa dalla stessa sessione. `Result` e risposte non sono cancellati direttamente.
In questo branch una sessione aggiornata tra selezione e cancellazione può essere
eliminata comunque. Le cancellazioni sono parziali se il job si interrompe.
Prima della prima esecuzione verificare backup, arretrato e tempi di attesa dei bot.

Lo script importa la funzione dal checkout a ogni avvio: con aggiornamenti
compatibili ne usa la nuova implementazione. Su `main` attualmente verificato le
soglie sono UTC e viene ricontrollata la data durante la cancellazione. Assicurarsi
che questi nuovi file siano inclusi nel branch di destinazione, aggiornare le
dipendenze ed eseguire `--check` dopo gli aggiornamenti. Se si sposta il repository
o Bun, registrare nuovamente l'attività dopo aver rimosso quella precedente.
