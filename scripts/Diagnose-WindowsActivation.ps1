# Ottieni il percorso della cartella in cui si trova lo script
$scriptPath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

# Creazione nome file con timestamp
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$txtReport = "$scriptPath\ActivationReport_$timestamp.txt"
$htmlReport = "$scriptPath\ActivationReport_$timestamp.html"

# StringBuilder per accumulare output
$txtBuilder = New-Object System.Text.StringBuilder
$htmlBuilder = New-Object System.Text.StringBuilder

# Funzioni utili
function Add-Report {
    param (
        [string]$Title,
        [string[]]$Content
    )
    $txtBuilder.AppendLine("==== $Title ====") | Out-Null
    $Content | ForEach-Object { $txtBuilder.AppendLine($_) | Out-Null }

    $htmlBuilder.AppendLine("<h2>$Title</h2><pre>$($Content -join "`n")</pre>") | Out-Null
}

# Inizio raccolta dati
Add-Report -Title "Connettività verso activation.microsoft.com" -Content (
    Test-NetConnection -ComputerName activation.microsoft.com -Port 443 | Out-String
)

Add-Report -Title "Proxy WinHTTP" -Content (
    netsh winhttp show proxy | Out-String
)

Add-Report -Title "Server DNS configurati" -Content (
    Get-DnsClientServerAddress | Where-Object {$_.ServerAddresses} | Format-Table InterfaceAlias, ServerAddresses -AutoSize | Out-String
)

Add-Report -Title "Stato dei servizi critici (sppsvc, wuauserv, W32Time, NlaSvc)" -Content (
    Get-Service -Name sppsvc, wuauserv, W32Time, NlaSvc | Format-Table Name, Status, StartType | Out-String
)

Add-Report -Title "Stato della licenza Windows (slmgr /dlv)" -Content (
    cscript.exe //Nologo C:\Windows\System32\slmgr.vbs /dlv 2>&1
)

Add-Report -Title "Hostname e Dominio" -Content (
    "Computer Name: $env:COMPUTERNAME",
    "Domain (USERDOMAIN): $env:USERDOMAIN"
)

# Salvataggio dei file
[System.IO.File]::WriteAllText($txtReport, $txtBuilder.ToString())
[System.IO.File]::WriteAllText($htmlReport, @"
<html>
<head>
    <title>Diagnostica Attivazione Windows</title>
    <style>
        body { font-family: Consolas, monospace; background-color: #f4f4f4; color: #333; padding: 20px; }
        h2 { color: #0066cc; border-bottom: 1px solid #ccc; }
        pre { background: #fff; padding: 10px; border: 1px solid #ccc; overflow-x: auto; }
    </style>
</head>
<body>
<h1>Report Diagnostica Attivazione Windows</h1>
$htmlBuilder
</body>
</html>
"@)

# Output finale
Write-Host "`n== Diagnostica completata ==" -ForegroundColor Green
Write-Host "Report salvati in: $scriptPath" -ForegroundColor Cyan
