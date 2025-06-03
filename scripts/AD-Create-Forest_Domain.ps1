<#
.SYNOPSIS
    Crea e configura una nuova foresta Active Directory e un dominio denominato "lab.local" su un server Windows.

.DESCRIPTION
    Questo script PowerShell automatizza l'installazione dei ruoli necessari (Active Directory Domain Services e DNS), 
    verifica i privilegi amministrativi, richiede la password DSRM, e promuove il server a Domain Controller per il dominio "lab.local".
    Se la promozione ha successo, il server verrà riavviato automaticamente.

.PARAMETER Nessuno
    Lo script non accetta parametri tramite riga di comando, ma richiede l'inserimento interattivo della password DSRM.

.NOTES
    - Deve essere eseguito con privilegi di amministratore.
    - Compatibile con Windows Server che supporta i cmdlet ADDS.
    - Personalizzare i parametri del dominio se necessario.

.AUTHOR
    andrea.balconi@cegeka.com

.EXAMPLE
    Esegui lo script come amministratore:
        .\AD-Create-Forest_Domain.ps1

    Segui le istruzioni a schermo per inserire la password DSRM.
#>
# ===============================
# Crea nuovo dominio lab.local
# ===============================

# Colori e stile output
function Info($msg) { Write-Host "🔹 $msg" -ForegroundColor Cyan }
function Ok($msg) { Write-Host "✅ $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "⚠️ $msg" -ForegroundColor Yellow }

# Verifica privilegi
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole("Administrator")) {
    throw "Devi eseguire questo script come amministratore!"
}

# Installa ruoli AD DS e DNS se non presenti
Info "Controllo ruoli AD DS e DNS..."

$roles = @("AD-Domain-Services", "DNS")
foreach ($role in $roles) {
    if (-not (Get-WindowsFeature -Name $role).Installed) {
        Info "Installo ruolo $role..."
        Install-WindowsFeature -Name $role -IncludeManagementTools -Verbose
    } else {
        Ok "Ruolo $role già installato."
    }
}

# Chiedi password DSRM
$dsrmPassword = Read-Host "🔐 Inserisci la password DSRM" -AsSecureString

# Richiedi parametri del dominio in modo interattivo
$domainName = Read-Host "🌐 Inserisci il nome del dominio (es. lab.local)"
$netbiosName = Read-Host "🖥️ Inserisci il nome NetBIOS del dominio (es. LAB)"

Info "Promuovo il server a Domain Controller per il dominio $domainName..."

Install-ADDSForest `
    -DomainName $domainName `
    -DomainNetbiosName $netbiosName `
    -SafeModeAdministratorPassword $dsrmPassword `
    -InstallDNS `
    -CreateDnsDelegation:$false `
    -DatabasePath "C:\Windows\NTDS" `
    -LogPath "C:\Windows\NTDS" `
    -SysvolPath "C:\Windows\SYSVOL" `
    -Force:$true

# ⚠️ Se il server viene promosso con successo, si riavvierà automaticamente