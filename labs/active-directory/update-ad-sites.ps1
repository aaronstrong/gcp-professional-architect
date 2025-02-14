# Define variables
$onPremSiteName = "on-prem-location"
$onPremSiteDescription = "Site1"
$cloudSiteName = "cloud-us-central1"
$cloudSiteDescription = "Site2"
$subnet1 = "10.0.0.0/16"
$subnet2 = "192.168.4.0/24"
$replicationLinkName = "on-prem-cloud-us-central1"
$replicationCost = 250
$replicationFrequency = 15
$transportProtocol = "IP"

# Create on-premises site
New-ADReplicationSite -Name $onPremSiteName -Description $onPremSiteDescription

# Create cloud site
New-ADReplicationSite -Name $cloudSiteName -Description $cloudSiteDescription

# Create replication site link
New-ADReplicationSiteLink -Name $replicationLinkName -SitesIncluded $onPremSiteName,$cloudSiteName -Cost $replicationCost -ReplicationFrequencyInMinutes $replicationFrequency -InterSiteTransportProtocol $transportProtocol

# Create subnets
New-ADReplicationSubnet -Name $subnet1 -Site $cloudSiteName
New-ADReplicationSubnet -Name $subnet2 -Site $onPremSiteName


$localHostName = (Get-ComputerInfo).CsName

Move-ADDirectoryServer -Identity $localHostName -Site "on-prem-location"
