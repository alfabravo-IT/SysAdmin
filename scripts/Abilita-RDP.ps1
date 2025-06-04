# ===============================================
# 📡 Abilitazione Desktop Remoto (RDP)
# ===============================================

Write-Host "`n🔧 Abilitazione Desktop Remoto in corso..." -ForegroundColor Cyan

# 1. Abilita RDP nel registro
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0

# 2. Attiva e avvia il servizio RDP
Set-Service -Name TermService -StartupType Automatic
Start-Service -Name TermService

# 3. Abilita tutte le regole Firewall per RDP
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# 4. Verifica lo stato della porta RDP dal registro
try {
    $rdpPort = (Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp").PortNumber
    if (-not $rdpPort) {
        Write-Host "⚠️  Impossibile determinare la porta RDP dal registro. Uso la porta di default 3389." -ForegroundColor Yellow
        $rdpPort = 3389
    }
} catch {
    Write-Host "❌ Errore durante la lettura della porta RDP dal registro. Uso la porta di default 3389." -ForegroundColor Red
    $rdpPort = 3389
}

Write-Host "`n✅ Desktop Remoto abilitato sulla porta: $rdpPort" -ForegroundColor Green
Write-Host "🔐 Regole firewall configurate correttamente." -ForegroundColor Green

# 5. Verifica se la porta è in ascolto
try {
    $rdpStatus = (Get-NetTCPConnection -LocalPort $rdpPort -ErrorAction SilentlyContinue).State
} catch {
    $rdpStatus = $null
}

if ($rdpStatus -eq "Listen") {
    Write-Host "🟢 RDP pronto a ricevere connessioni." -ForegroundColor Green
} else {
    Write-Host "⚠️  La porta RDP non risulta in ascolto. Potrebbe essere richiesto un riavvio." -ForegroundColor Yellow
}

# 6. Messaggio finale
Write-Host "`n✅ FINE. Ora puoi connetterti in RDP!" -ForegroundColor Cyan
Write-Host "🖥️  Riavvia il sistema per applicare tutte le modifiche." -ForegroundColor Yellow
