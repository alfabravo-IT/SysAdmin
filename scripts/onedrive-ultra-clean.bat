<#
.SYNOPSIS
  Ultra-Clean Script to remove OneDrive from Windows 10/11

.DESCRIPTION
  This script allows you to completely remove OneDrive from a Windows 10/11 system, both 32-bit and 64-bit.
  It performs the following operations:
  - Verifies that the script is run with administrator privileges.
  - Terminates the OneDrive process if it is active.
  - Uninstalls OneDrive for both 64-bit and 32-bit versions.
  - Modifies the registry to prevent file synchronization and remove residual OneDrive entries.
  - Registers the deletion of residual OneDrive folders upon system reboot.
  - Requires a reboot to complete the cleanup.

.NOTES
  Author   : Andrea Balconi (Cegeka)
  Date     : 29/04/2025
  Version  : 1.0
#>

@echo off
echo ===============================================
echo   Ultra-Clean Script to remove OneDrive
echo   Version: Windows 10/11 - 64bit and 32bit
echo ===============================================
echo.

:: Requires the prompt with administrative rights
whoami /groups | find "S-1-16-12288" >nul
if errorlevel 1 (
    echo [ERROR] You must run this script as ADMINISTRATOR.
    pause
    exit /b
)

:: Terminates the OneDrive process if active
echo Terminating OneDrive process...
taskkill /f /im OneDrive.exe >nul 2>&1

:: Uninstalls OneDrive for 64bit
echo Uninstalling OneDrive 64bit...
%SystemRoot%\SysWOW64\OneDriveSetup.exe /uninstall >nul 2>&1

:: Uninstalls OneDrive for 32bit
echo Uninstalling OneDrive 32bit...
%SystemRoot%\System32\OneDriveSetup.exe /uninstall >nul 2>&1

:: Registry modifications
echo Applying Registry modifications...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v DisableFileSync /t REG_DWORD /d 1 /f
reg add "HKCR\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}\ShellFolder" /v Attributes /t REG_DWORD /d f090004d /f
reg add "HKCR\CLSID\{04271989-C4D2-4F23-ADE4-8C8C98D444E2}\ShellFolder" /v Attributes /t REG_DWORD /d f090004d /f

:: Cleanup of residual folders or registration for deletion on reboot
if exist "%UserProfile%\OneDrive" (
    echo Registering OneDrive deletion on reboot...
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v PendingFileRenameOperations /t REG_MULTI_SZ /d "\??\%UserProfile%\OneDrive" /f
)

if exist "%LocalAppData%\Microsoft\OneDrive" (
    echo Registering Microsoft\OneDrive deletion on reboot...
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v PendingFileRenameOperations /t REG_MULTI_SZ /d "\??\%LocalAppData%\Microsoft\OneDrive" /f
)

echo.
echo ===============================================
echo   OneDrive completely removed!
echo   Restart your computer to complete the cleanup.
echo ===============================================
pause
exit