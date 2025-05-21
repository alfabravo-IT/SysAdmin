
# Abilitare RDS CAL su Windows Server 2022

## Obiettivo
Attivare e configurare le licenze RDS (Remote Desktop Services Client Access Licenses) su un server **Windows Server 2022** in **workgroup**.

---

## Prerequisiti

- Licenze RDS CAL valide (Per User o Per Device)
- Accesso come amministratore al server
- Connessione a Internet (per attivazione online)

---

## 1. Installazione dei ruoli RDS

### Passaggi manuali (GUI):
1. Apri **Server Manager**
2. Vai su **Manage > Add Roles and Features**
3. Segui il wizard fino a "Server Roles"
4. Seleziona:
   - Remote Desktop Services
5. Nella sezione **Role Services**, aggiungi:
   - Remote Desktop Licensing
   - Remote Desktop Session Host
6. Completa il wizard e riavvia il server se richiesto

### Comandi da CLI (PowerShell):
Esegui i seguenti comandi PowerShell come amministratore:

```powershell
# Installa il ruolo Remote Desktop Session Host
Install-WindowsFeature -Name RDS-RD-Server -IncludeManagementTools

# Installa il ruolo Remote Desktop Licensing
Install-WindowsFeature -Name RDS-Licensing -IncludeManagementTools
```
---

## 2. Configurazione modalità di licensing (via Registro)

### Licensing Mode
- `2` = Per Device (consigliato in workgroup)
- `4` = Per User

### Passaggi:

1. Apri **regedit**
2. Naviga a:
   ```
   HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\RCM\Licensing Core
   ```
3. Imposta o crea il valore DWORD:
   - `LicensingMode` = `2` (o `4`)
4. Poi vai a:
   ```
   HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\RCM
   ```
5. Crea (se non esiste) la chiave:
   ```
   LicenseServers
   ```
6. All'interno crea un valore **REG_SZ** con:
   - Nome del server locale (es. `NOMESERVER`) oppure IP locale

---

## 3. Attivazione del server licenze

1. Apri il tool:
   ```
   Remote Desktop Licensing Manager (licmgr.exe)
   ```
2. Click destro sul server > **Activate Server**
3. Segui il wizard:
   - Scegli Internet o attivazione telefonica
   - Inserisci le informazioni richieste
4. Dopo l’attivazione:
   - Click destro > **Install Licenses**
   - Seleziona tipo e quantità di licenze CAL

---

## 4. Verifica funzionamento

- Apri **Licensing Diagnoser** da Server Manager
- Verifica che:
  - Il server sia attivato
  - Le licenze siano installate
  - Non ci siano errori critici

---

## 5. Disabilitare il periodo di grazia (opzionale)

### Passaggi manuali (GUI):
1. Vai in regedit a:
   ```
   HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\RCM\GracePeriod
   ```
2. **Cambia proprietà** della chiave per ottenere i permessi
3. **Elimina la chiave `GracePeriod`**
   - Questo forza il server a usare subito le licenze CAL

### Comandi da CLI (PowerShell):

```powershell
# Prende possesso della chiave
takeown /f "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\RCM\GracePeriod" /a

# Imposta i permessi alla chiave
icacls "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\RCM\GracePeriod" /grant administrators:F /t

# Elimina la chiave GracePeriod
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\RCM\GracePeriod" /f
```

> **Attenzione**: L'eliminazione del GracePeriod è irreversibile. Assicurati che le CAL siano già installate e il server licenze attivo.


1. Vai in regedit a:
   ```
   HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\RCM\GracePeriod
   ```
2. **Cambia proprietà** della chiave per ottenere i permessi
3. **Elimina la chiave `GracePeriod`**
   - Questo forza il server a usare subito le licenze CAL

---

## 6. Comandi `reg add` per configurare il licensing via CLI

```cmd
:: Imposta la modalità di licensing (2 = Per Device, 4 = Per User)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\RCM\Licensing Core" /v LicensingMode /t REG_DWORD /d 2 /f

:: Crea la chiave LicenseServers (se non esiste)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\RCM\LicenseServers" /f

:: Aggiunge il nome del server delle licenze (sostituisci NOMESERVER con il nome effettivo)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\RCM\LicenseServers\NOMESERVER" /f
```

> **Nota:** Sostituisci `NOMESERVER` con il nome del tuo server delle licenze. Se il server delle licenze è lo stesso su cui stai eseguendo questi comandi, puoi utilizzare il nome del computer locale.

---

## Note finali

- In ambiente **Workgroup**, **le CAL Per User non vengono tracciate**, quindi:
  - Preferire **CAL Per Device** quando possibile
- Il server **non può gestire CAL Per User correttamente** fuori dal dominio
- Attenzione al limite delle **120 giornate di grazia** se non rimuovi `GracePeriod`
