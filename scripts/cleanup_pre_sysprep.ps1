# Esegui come amministratore
Write-Host "🧽 Inizio pulizia pre-Sysprep..." -ForegroundColor Cyan

# [1/4] Cleanmgr (solo se presente)
Write-Host "`n[1/4] Verifica presenza Cleanmgr..."
if (Test-Path "$env:SystemRoot\System32\cleanmgr.exe") {
    Write-Host "[✓] Cleanmgr trovato. Avvio in modalità verylowdisk..."
    Start-Process -FilePath "$env:SystemRoot\System32\cleanmgr.exe" -ArgumentList "/verylowdisk" -Wait
} else {
    Write-Host "[!] Cleanmgr non presente. Pulizia GUI saltata." -ForegroundColor Yellow
}

# [2/4] Pulizia cache aggiornamenti
Write-Host "`n[2/4] Rimozione cache aggiornamenti..."
Try {
    Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service wuauserv -ErrorAction SilentlyContinue
    Write-Host "[✓] Cache aggiornamenti rimossa."
} Catch {
    Write-Host "[X] Errore durante la rimozione degli aggiornamenti." -ForegroundColor Red
}

# [3/4] Pulizia log eventi (salta log protetti)
Write-Host "`n[3/4] Pulizia log eventi..."
$logs = wevtutil el
foreach ($log in $logs) {
    Try {
        wevtutil cl $log
    } Catch {
        Write-Host "⚠️ Log non cancellabile: $log" -ForegroundColor DarkYellow
    }
}
Write-Host "[✓] Pulizia log completata."

# [4/4] File temporanei
Write-Host "`n[4/4] Pulizia file temporanei..."
Try {
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "[✓] File temporanei rimossi."
} Catch {
    Write-Host "[X] Alcuni file temporanei non cancellabili." -ForegroundColor Red
}

Write-Host "`n✔️ Pulizia completata. Sistema pronto per Sysprep." -ForegroundColor Green