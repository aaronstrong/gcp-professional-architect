$domainName = "contoso.local"
$netbiosName = "contoso"
$safeModeAdminstratorPassword = ConvertTo-SecureString 'BestCloud1!' -AsPlainText -Force
$logpath = "C:\log\log.txt"
$domainMode = "Win2025"
$forestMode = "Win2025"

# Install Module
Install-WindowsFeature -Name RSAT-AD-PowerShell, RSAT-AD-AdminCenter, RSAT-ADDS -IncludeManagementTools
Install-WindowsFeature AD-Domain-Services
Import-Module ADDSDeployment

# Import-Module ADDSDeployment
Install-ADDSForest `
-CreateDnsDelegation:$false  `
-DatabasePath "C:\Windows\NTDS" `
-DomainMode $domainMode -ForestMode $forestMode `
-DomainName $domainName `
-DomainNetbiosName $netbiosname `
-LogPath "C:\Windows\NTDS" `
-NoRebootOnCompletion:$false `
-SysvolPath "C:\Windows\SYSVOL" `
-SafeModeAdministratorPassword $safeModeAdminstratorPassword `
-Force:$true
