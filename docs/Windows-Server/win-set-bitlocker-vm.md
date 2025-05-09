# 🛡️ Attivazione BitLocker con Password su VM (senza vTPM)

## ✅ 1. Requisiti minimi sulla VM

| Componente                        | Requisito                                     |
|----------------------------------|-----------------------------------------------|
| 🖥️ Firmware                      | **UEFI consigliato**, ma non obbligatorio     |
| 🧱 vTPM                          | ❌ **Non richiesto**                          |
| 🔐 VM Encryption                  | ❌ **Non richiesta**                          |
| 🔑 KMS VMware                     | ❌ **Non richiesto**                          |
| 💽 Windows Server                | Versione con supporto a BitLocker (2016+)     |
| 🔧 Feature BitLocker installata  | Deve essere presente nel sistema operativo    |
| 🔌 Accesso console                | **Obbligatorio** (per inserire la password al boot) |

> ⚠️ Il server non si avvierà da solo: sarà necessaria l'interazione manuale per inserire la password BitLocker ad ogni riavvio.

---

## 🛠️ 2. Script PowerShell per abilitare BitLocker con password

Questo script:
- Richiede all’utente la password BitLocker.
- Attiva la cifratura solo dello spazio usato.
- Salva la Recovery Key in una cartella specifica.

```powershell
# === CONFIGURAZIONE ===
$RecoveryPath = (Get-Location).Path + "\BitLockerRecoveryKeys"
$TimeStamp = Get-Date -Format "yyyyMMdd-HHmmss"
$ComputerName = $env:COMPUTERNAME
$RecoveryFile = "$RecoveryPath\${ComputerName}_BitLockerKey_$TimeStamp.txt"

# === CREA CARTELLA DI RECUPERO SE NON ESISTE ===
if (-not (Test-Path -Path $RecoveryPath)) {
    New-Item -Path $RecoveryPath -ItemType Directory -Force
}

# === CHIEDI PASSWORD ===
$password = Read-Host -Prompt "Inserisci la password BitLocker da usare all'avvio" -AsSecureString

# === ABILITA BITLOCKER CON PASSWORD ===
Enable-BitLocker -MountPoint "C:" -EncryptionMethod XtsAes256 `
    -PasswordProtector -Password $password -UsedSpaceOnly -Verbose

# === ATTENDI ATTIVAZIONE ===
Write-Host "Attivazione BitLocker in corso, attendere..."
do {
    Start-Sleep -Seconds 5
    $status = Get-BitLockerVolume -MountPoint "C:"
} while ($status.ProtectionStatus -ne 'On')

# === ESTRAI RECOVERY KEY ===
$keyProtector = Get-BitLockerVolume -MountPoint "C:" |
    Select-Object -ExpandProperty KeyProtector |
    Where-Object {$_.KeyProtectorType -eq "RecoveryPassword"}

"Recovery Key for $ComputerName - $TimeStamp" | Out-File $RecoveryFile -Encoding UTF8
"Recovery Password: $($keyProtector.RecoveryPassword)" | Out-File $RecoveryFile -Append -Encoding UTF8

Write-Output "`n✅ BitLocker attivato con password. Recovery salvata in: $RecoveryFile"
```

---

## 🧯 Note operative

- 👁️‍🗨️ L’utente dovrà **digitare la password manualmente** a ogni avvio.
- 🔐 La **Recovery Key** deve essere conservata in un luogo sicuro (vault o backup offline).
- 🧪 Non adatto a sistemi che richiedono **riavvio automatico**, tipo cluster o ambienti ad alta disponibilità.

---

## 🧰 Suggerimento extra

Per controllare se BitLocker è già attivo sulla macchina prima di eseguire lo script:

```powershell
(Get-BitLockerVolume -MountPoint "C:").ProtectionStatus
```

- **1** = Attivo  
- **0** = Non attivo
