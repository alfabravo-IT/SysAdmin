
# Delegate Permissions on Windows Service

## Description

This guide shows how to **delegate start and stop permissions on a specific Windows service** to a user or group without granting full administrative privileges.  
Delegation is achieved by modifying the service's Security Descriptor (SDDL).

---

## PowerShell Script

```powershell
<#
.SYNOPSIS
    Delegate Start/Stop access to a specific service for a user or group.

.DESCRIPTION
    This script:
    - Checks the provided service name
    - Retrieves the SID of the specified user/group
    - Displays the current Security Descriptor (SDDL)
    - Applies a new ACL allowing Start/Stop of the service

.NOTES
    Run as administrator.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ServiceName,

    [Parameter(Mandatory=$true)]
    [string]$TargetAccount  # e.g. "DOMAIN\Technicians"
)

# Get SID
try {
    $sid = (New-Object System.Security.Principal.NTAccount($TargetAccount)).Translate([System.Security.Principal.SecurityIdentifier]).Value
    Write-Host "`nSID for ${TargetAccount}: ${sid}`n"
} catch {
    Write-Error "Error retrieving SID for ${TargetAccount}. Check the username or group name."
    exit 1
}

# Show current SDDL
Write-Host "Current SDDL for service ${ServiceName}:"
$currentSDDL = sc.exe sdshow $ServiceName
if (!$currentSDDL) {
    Write-Warning "No SDDL retrieved. There may be a permissions issue or the service is protected."
    exit 1
}
Write-Host $currentSDDL

# Create new ACE for Start/Stop (RP, WP) + read config (LC)
$newACE = "(A;;RPWP;;;${sid})"

# Insert new ACE at the beginning of the DACL (after "D:")
$newSDDL = $currentSDDL -replace "^D:\(", "D:($newACE"
Write-Host "`nProposed new SDDL:"
Write-Host $newSDDL

# Confirm before applying
$apply = Read-Host "`nApply new SDDL to service ${ServiceName}? (Y/N)"
if ($apply -eq "Y") {
    sc.exe sdset $ServiceName $newSDDL
    Write-Host "✅ SDDL updated."
} else {
    Write-Host "❌ Operation cancelled."
}
```

---

## SDDL Permission Codes Used

| Code | Meaning                        |
|------|-------------------------------|
| RP   | Permission to start the service|
| WP   | Permission to stop the service |
| LC   | Permission to read configuration|

---

## Final Notes

- The script must be run in a console with **administrative privileges**.  
- The `$ServiceName` parameter is the technical name of the service (not the display name).  
- The `$TargetAccount` parameter is the username or group to which you want to delegate permission (e.g. `DOMAIN\Technicians`).  
- It is recommended to back up the original SDDL before making changes.  

---

## Example Usage

```powershell
.\Set-DelegatedAccess.ps1 -ServiceName "winlogbeat" -TargetAccount "DOMAIN\Technicians"
```

---

With this procedure, you can securely and granularly delegate control of a service without granting full administrative privileges.

