# Procedure to Restore Windows Service Permissions via Scheduled Task

## Description

This guide shows how to restore the Security Descriptor (permissions) of a “broken” or misconfigured Windows service by using a scheduled task run with SYSTEM privileges.

---

## Manual Steps

1. **Dump the SDDL from a known-good machine**

   Run this on a healthy machine:

       sc sdshow ServiceName > Service-SDDL.txt

   Save the SDDL string representing the correct permissions.

2. **Create a scheduled task on the broken machine**

   Open an elevated PowerShell console and create a scheduled task to run:

       %SystemRoot%\System32\sc.exe sdset ServiceName "paste_the_good_SDDL_here"

   - Configure the task to run as **SYSTEM**  
   - Set the task to run **manually**, no triggers

3. **Manually run the scheduled task**

   Execute the task manually to apply the correct permissions.

4. **Disable or delete the scheduled task**

   After verifying proper service operation, disable or remove the task for security.

---

## Automation PowerShell Script

This script automates the creation, execution, and removal of the scheduled task to restore service permissions.

    param(
        [Parameter(Mandatory=$true)]
        [string]$ServiceName,

        [Parameter(Mandatory=$true)]
        [string]$SDDL
    )

    $taskName = "RestoreServiceSDDL_$ServiceName"

    # Create the scheduled task action
    $action = New-ScheduledTaskAction -Execute "sc.exe" -Argument "sdset $ServiceName `"$SDDL`""

    # Create the scheduled task principal SYSTEM
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

    # Create the scheduled task without triggers (manual)
    $task = New-ScheduledTask -Action $action -Principal $principal

    # Register the scheduled task
    Register-ScheduledTask -TaskName $taskName -InputObject $task -Force

    Write-Host "Scheduled task '$taskName' created. It will now be run..."

    # Run the task manually
    Start-ScheduledTask -TaskName $taskName

    Write-Host "Scheduled task executed. Verify the service is working correctly."

    # Remove the task
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Write-Host "Scheduled task removed. Operation complete."

---

## Notes

- Run the script with administrative privileges.  
- Replace `$ServiceName` with the service’s actual name (e.g., `spooler`, `winlogbeat`).  
- Paste the SDDL string obtained from the good machine into the `$SDDL` parameter.

---

## Usage Example

    .\Restore-ServicePermissions.ps1 -ServiceName "spooler" -SDDL "D:(A;;CCLCSWLOCRRC;;;AU)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)..."

---