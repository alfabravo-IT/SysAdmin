# Ask the user for parameters
$DomainName = Read-Host "Enter the name of the existing domain (e.g., contoso.local)"
$SafeModePassword = Read-Host "Enter the DSRM recovery password" -AsSecureString

# Install the AD DS role
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Add this server as an additional Domain Controller
Install-ADDSDomainController `
    -DomainName $DomainName `
    -InstallDNS `
    -Credential (Get-Credential -Message "Enter domain credentials with Domain Admin rights") `
    -SafeModeAdministratorPassword $SafeModePassword `
    -DatabasePath "C:\Windows\NTDS" `
    -LogPath "C:\Windows\NTDS" `
    -SysvolPath "C:\Windows\SYSVOL" `
    -NoRebootOnCompletion:$false `
    -Force:$true `
    -Confirm:$false