# Remove-GhostNetworkAdapters.ps1
# This script lists and optionally removes ghost (non-present) network adapters.

# Define log path based on script location
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logPath = Join-Path -Path $PSScriptRoot -ChildPath "ghost_nic_cleanup_$timestamp.log"

# Create log directory if needed
if (-not (Test-Path -Path $PSScriptRoot)) {
    New-Item -ItemType Directory -Path $PSScriptRoot -Force | Out-Null
}

Write-Host "\Scanning for ghost (non-present) network adapters..." -ForegroundColor Cyan

# Get ghost network adapters (those in 'Unknown' or 'Error' state)
$ghostNics = Get-PnpDevice -Class Net | Where-Object { $_.Status -eq "Unknown" -or $_.Status -eq "Error" }

# Log the detected ghost adapters
$ghostNics | Select-Object Name, Status, InstanceId | Out-File -FilePath $logPath -Encoding UTF8
Write-Host "\nReport saved to: $logPath" -ForegroundColor Yellow

if ($ghostNics.Count -eq 0) {
    Write-Host "No ghost adapters found. System is clean." -ForegroundColor Green
    return
}

Write-Host "\nFound $($ghostNics.Count) ghost network adapter(s)."
$confirm = Read-Host "Do you want to remove them now? (y/n)"

if ($confirm -match "^[yY]") {
    $ghostNics | ForEach-Object {
        Write-Host "Removing: $($_.Name)" -ForegroundColor DarkYellow
        try {
            Remove-PnpDevice -InstanceId $_.InstanceId -Confirm:$false
            Write-Host "Removed: $($_.Name)" -ForegroundColor Green
        } catch {
            Write-Host "Failed to remove $($_.Name): $_" -ForegroundColor Red
        }
    }
    Write-Host "\nCleanup complete!" -ForegroundColor Cyan
} else {
    Write-Host "\nNo changes made. Review the log file for details." -ForegroundColor Gray
}
