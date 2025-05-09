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