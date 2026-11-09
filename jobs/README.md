# Job pianificati

Ogni sottocartella contiene un progetto Nx indipendente, lo script di avvio
Windows, la registrazione dell'attività pianificata e la documentazione del job.
I comandi vanno eseguiti dalla radice del repository, ad esempio `C:\typebot`.

| Job | Target Nx | Pianificazione |
| --- | --- | --- |
| [cleanup-expired-data](./cleanup-expired-data/README.md) | `cleanup-expired-data:run` | Ogni giorno alle 05:30 UTC |

Per aggiungere altri job, creare una sottocartella con un `project.json` che
definisca un nome progetto univoco e un target senza cache. Ogni job deve avere
un'attività Windows con nome e schedulazione propri, log separati e un exit code
che segnali gli errori. Non è necessario modificare `packages/scripts/package.json`.

La protezione dalle sovrapposizioni vale per la singola attività pianificata:
job diversi possono girare contemporaneamente. Se condividono risorse pesanti,
scegliere orari che evitino interferenze. La registrazione delle attività deve
essere eseguita sul server: il semplice aggiornamento del repository non le crea.
