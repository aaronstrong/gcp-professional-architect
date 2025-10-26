
${functions}

$ErrorActionPreference = "stop"


#
# Read configuration from metadata.
#
Import-Module "$${Env:ProgramFiles}\Google\Compute Engine\sysprep\gce_base.psm1"

$Hostname = Get-MetaData -Property "attributes/instanceName" -instance_only


#
# Install required Windows features
#
Install-WindowsFeature Failover-Clustering -IncludeManagementTools
Install-WindowsFeature RSAT-AD-PowerShell
Install-WindowsFeature -Name Web-Server -IncludeManagementTools

Write-Host "Hostname is: $Hostname"

# remove default htm file
remove-item  C:\inetpub\wwwroot\iisstart.htm

# Add a new htm file that displays server name
Add-Content -Path "C:\inetpub\wwwroot\iisstart.htm" -Value $("Hello World from " + $Hostname)

# Open firewall for WSFC
netsh advfirewall firewall add rule name="Allow SQL Server health check" dir=in action=allow protocol=TCP localport=${health_check_port}

# Open firewall for SQL Server
netsh advfirewall firewall add rule name="Allow SQL Server" dir=in action=allow protocol=TCP localport=1433






Write-Host "Setting static ip address...$Hostname"

if ($Hostname -eq "wsfc-1") {
    Write-Host "Setting static ip for $Hostname"

    # Set Static IP
    Set-StaticNetworkConfiguration -IPAddress ${node1_ip} -SubnetMask 255.255.255.0 -Gateway 10.0.0.1 -DNSServers ("10.0.0.1") -AdapterName "Ethernet"
}

if ($Hostname -eq "wsfc-2") {
    Write-Host "Setting static ip for $Hostname"

    # Set Static IP
    Set-StaticNetworkConfiguration -IPAddress ${node2_ip} -SubnetMask 255.255.255.0 -Gateway 10.0.0.1 -DNSServers ("10.0.0.1") -AdapterName "Ethernet"
}


Restart-Computer