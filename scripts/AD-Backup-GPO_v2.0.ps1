<#
.SYNOPSIS
    Script to perform backup of Group Policy Objects (GPO) in an Active Directory domain.

.DESCRIPTION
    This script performs a backup of all GPOs in the domain except for the default ones, creating an organized and secure folder structure.
    Each GPO is saved in a subfolder named with the sanitized GPO name for filesystem use.
    Supports error handling during the backup process.

.PARAMETER BackupPath
    Path where backups will be saved. By default, a "backup-gpo" folder in the same directory as the script.

.PARAMETER Exclude
    List of GPOs to exclude from the backup. By default: "Default Domain Policy", "Default Domain Controllers Policy".

.EXAMPLE
    .\Backup-GPO.ps1
    Performs a backup of GPOs excluding the default policies in the local "backup-gpo" directory.

.EXAMPLE
    .\Backup-GPO.ps1 -BackupPath "D:\GPO_Backups" -Exclude @("GPO Test", "Default Domain Policy")

.NOTES
    Author   : Andrea Balconi (Cegeka)
    Date     : 29/04/2025
    Version  : 2.0
    Requirements:
        - ActiveDirectory module
        - Administrative permissions to access GPOs
#>

param (
    [string]$BackupPath = "$PSScriptRoot\backup-gpo",
    [string[]]$Exclude = @("Default Domain Policy", "Default Domain Controllers Policy")
)

# Create the base directory if it does not exist
if (!(Test-Path -Path $BackupPath)) {
    New-Item -ItemType Directory -Path $BackupPath | Out-Null
}

# Get all GPOs except the excluded ones
$GPOs = Get-GPO -All | Where-Object { $Exclude -notcontains $_.DisplayName }

# Perform the backup of each GPO
foreach ($GPO in $GPOs) {
    try {
        # Sanitize the GPO name to make it safe for the filesystem
        $SanitizedName = $GPO.DisplayName -replace '[\\/:*?"<>|]', '_' -replace '\s+', '_'
        $TargetPath = Join-Path -Path $BackupPath -ChildPath $SanitizedName

        # Create the GPO folder if it does not exist
        if (!(Test-Path -Path $TargetPath)) {
            New-Item -ItemType Directory -Path $TargetPath | Out-Null
        }

        # Perform the backup
        Backup-GPO -Name $GPO.DisplayName -Path $TargetPath -Comment "Backup on $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ErrorAction Stop
        Write-Host "Backup completed: $($GPO.DisplayName)"
    } catch {
        Write-Host "GPO backup failed: $($GPO.DisplayName). Error: $_"
    }
}

Write-Host ""
Write-Host "Backup of all GPOs completed in: $BackupPath"
Write-Host "Remember to copy the backup files to a secure location."
Write-Host "Ensure you have the appropriate permissions to access and restore the GPOs."
Write-Host "To restore the GPOs, use the script 'AD-Restore-GPO.ps1'."
Write-Host "End of script."
Write-Host "Script executed successfully."