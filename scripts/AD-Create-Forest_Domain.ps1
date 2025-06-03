# ========================================
# Script completo per creare un dominio lab.local
# Autore: Andrea (aka SysAdmin che non molla)
# ========================================

function Info($msg)  { Write-Host "🔹 $msg" -ForegroundColor Cyan }
function Ok($msg)    { Write-Host "✅ $msg" -ForegroundColor Green }
function Warn($msg)  { Write-Host "⚠️ $msg" -ForegroundColor Yellow }
function Fail($msg)  { Write-Host "❌ $msg" -ForegroundColor Red }

# Verifica esecuzione come amministratore
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole("Administrator")) {
    Fail "Devi eseguire questo script come amministratore!"
    exit 1
}

# Step 1: Installa i ruoli e moduli richiesti
$features = @("AD-Domain-Services", "DNS", "RSAT-AD-PowerShell")
$missing = $features | Where-Object { -not (Get-WindowsFeature $_).Installed }

if ($missing.Count -gt 0) {
    Info "Installo i seguenti componenti: $($missing -join ', ')"
    Install-WindowsFeature -Name $missing -IncludeManagementTools -Verbose

    Warn "Riavvia la macchina per completare l'installazione dei moduli. Poi rilancia lo script."
    pause
    exit
} else {
    Ok "Tutti i ruoli e moduli richiesti sono già presenti."
}

# Step 2: Verifica se il modulo è disponibile
if (-not (Get-Command Install-ADDSForest -ErrorAction SilentlyContinue)) {
    Fail "Modulo ADDSDeployment non trovato. Chiudi e riapri PowerShell come Admin dopo l'installazione dei ruoli."
    exit 1
}

# Step 3: Parametri dominio (inserimento interattivo)
$domainName = Read-Host "🌐 Inserisci il nome del dominio (es: lab.local)"
$netbiosName = Read-Host "🖥️  Inserisci il nome NetBIOS (es: LAB)"

# Step 4: Chiedi password DSRM in modo sicuro
$dsrmPassword = Read-Host "🔐 Inserisci la password DSRM (ripristino directory)" -AsSecureString

# Step 5: Promozione a Domain Controller
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

# La macchina si riavvierà automaticamente al termine.