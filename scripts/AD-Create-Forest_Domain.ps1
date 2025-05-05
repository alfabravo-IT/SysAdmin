# Asks the user to enter the parameters
$DomainName = Read-Host "Enter the domain name (e.g., mydomain.local)"
$NetBIOSName = Read-Host "Enter the NetBIOS name of the domain (e.g., MYDOMAIN)"
$SafeModePassword = Read-Host "Enter the DSRM recovery password" -AsSecureString

# Installs the Active Directory Domain Services role
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Promotes the server to a domain controller and creates a new forest
Install-ADDSForest `
    -DomainName $DomainName `
    -DomainNetbiosName $NetBIOSName `
    -ForestMode WinThreshold `
    -DomainMode WinThreshold `
    -InstallDNS `
    -CreateDnsDelegation:$false `
    -DatabasePath "C:\Windows\NTDS" `
    -LogPath "C:\Windows\NTDS" `
    -SysvolPath "C:\Windows\SYSVOL" `
    -NoRebootOnCompletion:$false `
    -SafeModeAdministratorPassword $SafeModePassword `
    -Force:$true `
    -Confirm:$false