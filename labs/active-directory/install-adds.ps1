<#

Create new forest with the parameters defined under Variables

#>
# VARIABLES #
$domainName = "contoso.local"
$netbiosName = "contoso"
$safeModeAdminstratorPassword = ConvertTo-SecureString 'VMware1!' -AsPlainText -Force
$logpath = "C:\log\log.txt"
$domainMode = "Win2012R2"
$forestMode = "Win2012R2"

# check if log folder exists
if(!(Test-Path $logpath)){    New-item -ItemType File -Path $logpath -ErrorAction Ignore -Force }

New-Item $logpath -ItemType file -Force

# Install Active Directory Roles
Start-Job -Name addfeature -ScriptBlock {
Add-WindowsFeature -Name "ad-domain-services" -IncludeAllSubFeature -IncludeManagementTools
Add-WindowsFeature -Name "dns" -IncludeAllSubFeature -IncludeManagementTools
Add-WindowsFeature -Name "gpmc" -IncludeAllSubFeature -IncludeManagementTools
}
Wait-Job -Name addfeature

Get-WindowsFeature | Where-Object installed >> $logpath

# # Install new Active Directory Forest
# Import-Module ADDSDeployment

# Install-ADDSForest `
# -CreateDnsDelegation:$false  `
# -DatabasePath "C:\Windows\NTDS" `
# -DomainMode $domainMode -ForestMode $forestMode `
# -DomainName $domainName `
# -DomainNetbiosName $netbiosname `
# -LogPath "C:\Windows\NTDS" `
# -NoRebootOnCompletion:$false `
# -SysvolPath "C:\Windows\SYSVOL" `
# -SafeModeAdministratorPassword $safeModeAdminstratorPassword `
# -Force:$true

# Restart-Computer