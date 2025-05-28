<#
.SYNOPSIS
    Script PowerShell interattivo per backup e importazione GPO.

.DESCRIPTION
    Esegue il backup di tutte le GPO (escludendo quelle predefinite)
    e permette l'importazione interattiva da una cartella di backup.
    Se la GPO esiste già, viene creata con il suffisso "_imported".

.NOTES
    Autore: Assistant
#>

function Show-Menu {
    param ([string]$title = 'Menu principale')
    Write-Host "================ $title ================" -ForegroundColor Cyan
    Write-Host "1: Esegui il backup di tutte le GPO"
    Write-Host "2: Importa una o più GPO da un backup"
    Write-Host "0: Esci"
    Write-Host "========================================"
}

function Backup-AllGPOs {
    param ([string]$BackupPath)

    if (!(Test-Path -Path $BackupPath)) {
        New-Item -ItemType Directory -Path $BackupPath | Out-Null
    }

    $gpos = Get-GPO -All
    foreach ($gpo in $gpos) {
        if ($gpo.DisplayName -ne "Default Domain Policy" -and $gpo.DisplayName -ne "Default Domain Controllers Policy") {
            $gpoBackupPath = Join-Path -Path $BackupPath -ChildPath $gpo.DisplayName
            if (!(Test-Path -Path $gpoBackupPath)) {
                New-Item -ItemType Directory -Path $gpoBackupPath | Out-Null
            }
            Backup-GPO -Name $gpo.DisplayName -Path $gpoBackupPath
            Write-Host "✅ Backup della GPO '$($gpo.DisplayName)' completato." -ForegroundColor Green
        }
    }
}

function Import-GPOFromBackup {
    param ([string]$BackupPath)

    if (!(Test-Path -Path $BackupPath)) {
        Write-Host "❌ Il percorso '$BackupPath' non esiste." -ForegroundColor Red
        return
    }

    do {
        $gpoBackups = Get-ChildItem -Path $BackupPath -Directory
        if ($gpoBackups.Count -eq 0) {
            Write-Host "⚠️ Nessun backup GPO trovato in '$BackupPath'." -ForegroundColor Yellow
            return
        }

        Write-Host "`n📦 GPO disponibili per l'import:"
        for ($i = 0; $i -lt $gpoBackups.Count; $i++) {
            Write-Host "$($i): $($gpoBackups[$i].Name)"
        }
        Write-Host "$($gpoBackups.Count): Torna al menu principale"

        $selection = Read-Host "👉 Inserisci il numero della GPO da importare"
        if ($selection -eq $gpoBackups.Count) {
            return
        }

        if ($selection -ge 0 -and $selection -lt $gpoBackups.Count) {
            $selectedGpoBackup = $gpoBackups[$selection]
            $targetGpoName = $selectedGpoBackup.Name

            if (Get-GPO -All | Where-Object { $_.DisplayName -eq $targetGpoName }) {
                $targetGpoName = "$targetGpoName`_imported"
                Write-Host "⚠️ GPO esistente. Verrà creata come '$targetGpoName'."
            }

            New-GPO -Name $targetGpoName | Out-Null
            Import-GPO -BackupGpoName $selectedGpoBackup.Name -Path $selectedGpoBackup.FullName -TargetName $targetGpoName
            Write-Host "✅ Importazione completata come '$targetGpoName'." -ForegroundColor Green
        } else {
            Write-Host "❌ Selezione non valida." -ForegroundColor Red
        }

    } while ($true)
}

do {
    Show-Menu
    $choice = Read-Host "Scegli un'opzione"
    switch ($choice) {
        1 {
            $backupPath = Read-Host "📂 Inserisci il percorso di destinazione per il backup"
            Backup-AllGPOs -BackupPath $backupPath
        }
        2 {
            $backupPath = Read-Host "📂 Inserisci il percorso dove si trovano i backup"
            Import-GPOFromBackup -BackupPath $backupPath
        }
        0 {
            Write-Host "👋 Uscita..." -ForegroundColor Cyan
        }
        default {
            Write-Host "❌ Opzione non valida. Riprova." -ForegroundColor Red
        }
    }
} while ($choice -ne 0)
