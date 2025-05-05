<#
.SYNOPSIS
    Script for backing up and restoring local security settings and Group Policies (GPO).

.DESCRIPTION
    This script performs the following operations:
    1. Checks and creates a backup directory if it does not exist.
    2. Backs up local security settings (SECPOL) using the `secedit` command.
    3. Backs up the `GroupPolicy` and `GroupPolicyUsers` folders from `C:\Windows\System32\`.
    4. Restores the `GroupPolicy` and `GroupPolicyUsers` folders on a new standalone server.
    5. Restores local security settings using the `secpol.inf` backup file.
    6. Forces a group policy update using `gpupdate`.
    7. Allows the user to choose whether to perform a backup or a restore.

.NOTES
    Author: Andrea Balconi (Cegeka)
    Date: 29/04/2025
    Version: 2.0
#>

# Set the backup directory
$backupDir = "$PSScriptRoot\backup_gpo"

# Check if the backup directory exists, otherwise create it
if (-not (Test-Path -Path $backupDir)) {
        Write-Host "The backup directory does not exist. Creating directory: $backupDir" -ForegroundColor Yellow
        New-Item -Path $backupDir -ItemType Directory -Force
}

# Prompt to choose whether to perform a backup or restore
$choice = Read-Host "Choose an option (1 for Backup, 2 for Restore)"

switch ($choice) {
        # Perform the backup
        1 {
                Write-Host "== PERFORMING BACKUP OF GPO AND SECPOL ==" -ForegroundColor Cyan
                
                # Backup SECPOL (local security settings)
                try {
                        Write-Host "Backing up SECPOL settings..." -ForegroundColor Cyan
                        secedit /export /cfg "$backupDir\secpol.inf"
                        Write-Host "SECPOL backup completed successfully." -ForegroundColor Green
                } catch {
                        Write-Error "Error during SECPOL backup: $_"
                }

                # Backup local Group Policies
                try {
                        Write-Host "Backing up local Group Policies..." -ForegroundColor Cyan
                        Copy-Item -Path "C:\Windows\System32\GroupPolicy" -Destination "$backupDir\GroupPolicy" -Recurse -ErrorAction Stop
                        Copy-Item -Path "C:\Windows\System32\GroupPolicyUsers" -Destination "$backupDir\GroupPolicyUsers" -Recurse -ErrorAction Stop
                        Write-Host "Group Policy backup completed successfully." -ForegroundColor Green
                } catch {
                        Write-Error "Error during Group Policy backup: $_"
                }

                Write-Host "== BACKUP COMPLETE ==" -ForegroundColor Cyan
                Write-Host "Check the report for any errors or anomalies." -ForegroundColor Yellow
                Write-Host "Script executed on: $(Get-Date)" -ForegroundColor Gray
                break
        }

        # Perform the restore
        2 {
                Write-Host "== PERFORMING RESTORE OF GPO AND SECPOL ==" -ForegroundColor Cyan

                # Restore local Group Policies
                try {
                        Write-Host "Restoring local Group Policies..." -ForegroundColor Cyan
                        Copy-Item -Path "$backupDir\GroupPolicy" -Destination "C:\Windows\System32\GroupPolicy" -Recurse -Force
                        Copy-Item -Path "$backupDir\GroupPolicyUsers" -Destination "C:\Windows\System32\GroupPolicyUsers" -Recurse -Force
                        Write-Host "Group Policy restore completed successfully." -ForegroundColor Green
                } catch {
                        Write-Error "Error during Group Policy restore: $_"
                }

                # Restore local security settings (SECPOL)
                try {
                        Write-Host "Restoring SECPOL settings..." -ForegroundColor Cyan
                        secedit /configure /db C:\Windows\Security\Database\local-import.sdb /cfg "$backupDir\secpol.inf" /quiet
                        Write-Host "SECPOL restore completed successfully." -ForegroundColor Green
                } catch {
                        Write-Error "Error during SECPOL restore: $_"
                }

                # Force update of local group policies
                try {
                        Write-Host "Forcing group policy update..." -ForegroundColor Cyan
                        gpupdate /force
                        Write-Host "Group policies updated successfully." -ForegroundColor Green
                } catch {
                        Write-Error "Error during group policy update: $_"
                }

                Write-Host "== RESTORE COMPLETE ==" -ForegroundColor Cyan
                Write-Host "Check the report for any errors or anomalies." -ForegroundColor Yellow
                Write-Host "Script executed on: $(Get-Date)" -ForegroundColor Gray
                break
        }

        # Invalid case
        default {
                Write-Host "Invalid option. Please choose 1 for backup or 2 for restore." -ForegroundColor Red
                break
        }
}

# End of script