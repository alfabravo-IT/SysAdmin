<#
    Author   : Andrea Balconi (Cegeka)
    Date     : 29/04/2025
    Version  : 1.0

    Script for restoring GPOs from previously created backups.

    === Features ===
    - Scans the directory containing GPO backups (one folder per GPO).
    - For each folder:
        - If the GPO already exists, it is overwritten.
        - If it does not exist, it is created and then restored.
    - Displays the restoration status for each GPO on the screen.

    === Requirements ===
    - Valid backup existing in named subfolders in the specified directory.
    - Active Directory module available.
    - Administrative permissions for creating or restoring GPOs.

    === Usage ===
    Place the script in the same directory containing the `backup-GPO` folder.
    Run with administrative privileges in a domain-connected environment.
#>

# === Script start ===

# Main backup folder (assumes it is in the same directory as the script)
$BackupRoot = Join-Path -Path $PSScriptRoot -ChildPath "backup-GPO"

# Get all subfolders – each folder represents a GPO backup
$BackupFolders = Get-ChildItem -Path $BackupRoot -Directory -ErrorAction Stop

foreach ($Folder in $BackupFolders) {
    $GpoName = $Folder.Name
    $BackupPath = $Folder.FullName

    # Check if the GPO already exists
    $ExistingGpo = Get-GPO -Name $GpoName -ErrorAction SilentlyContinue

    if ($ExistingGpo) {
        Write-Host "GPO '$GpoName' already exists. Overwriting..."
        Restore-GPO -Name $GpoName -Path $BackupPath -Confirm:$false
    } else {
        Write-Host "Creating new GPO: $GpoName"
        New-GPO -Name $GpoName | Out-Null
        Restore-GPO -Name $GpoName -Path $BackupPath -Confirm:$false
    }

    Write-Host "GPO '$GpoName' restored successfully."
}

Write-Host "Restoration completed from: $BackupRoot"
Write-Host "Remember to verify the restored GPOs for any post-restoration adjustments."
Write-Host "Also check permissions and delegations to ensure they are correct."
Write-Host "End of script."