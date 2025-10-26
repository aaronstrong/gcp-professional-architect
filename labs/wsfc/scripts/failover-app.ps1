 # Variables
$groupName = "iis"
$capName = "IIS-CAP"
$dnsName = "IIS-CAP"  # DNS name for the Client Access Point
$ipAddress = "10.0.0.9"
$subnetMask = "255.255.255.0"
$networkName = (Get-ClusterNetwork | Where-Object { $_.Address -like "10.*" }).Name

# Verify network was found
if (-not $networkName) {
    Write-Error "Could not find a cluster network matching '10.*'. Please verify your network configuration."
    exit
}

Write-Host "Using cluster network: $networkName"

# Step 1: Verify the cluster group exists
$clusterGroup = Get-ClusterGroup -Name $groupName -ErrorAction SilentlyContinue
if (-not $clusterGroup) {
    Write-Host "Creating cluster group '$groupName'..."
    $clusterGroup = Add-ClusterGroup -Name $groupName
} else {
    Write-Host "Cluster group '$groupName' already exists."
}

# Step 2: Take the group offline if it's online (to prevent auto-online of new resources)
if ($clusterGroup.State -eq "Online") {
    Write-Host "Taking group '$groupName' offline temporarily for configuration..."
    Stop-ClusterGroup -Name $groupName
}

# Step 3: Add the IP Address Resource
Write-Host "Adding IP Address resource..."
Add-ClusterResource -Name "$capName-IP" -ResourceType "IP Address" -Group $groupName | Out-Null

# Step 4: Configure IP address parameters using resource name
Write-Host "Configuring IP Address resource..."
Set-ClusterParameter -InputObject "$capName-IP" -Name Address -Value $ipAddress
Set-ClusterParameter -InputObject "$capName-IP" -Name SubnetMask -Value $subnetMask
Set-ClusterParameter -InputObject "$capName-IP" -Name Network -Value $networkName
Set-ClusterParameter -InputObject "$capName-IP" -Name EnableDhcp -Value 0

# Verify configuration
Write-Host "Verifying IP configuration..."
Get-ClusterResource "$capName-IP" | Get-ClusterParameter | Where-Object {$_.Name -in @('Address','SubnetMask','Network','EnableDhcp')} | Format-Table Name, Value -AutoSize

# Step 5: Add the Network Name resource
Write-Host "Adding Network Name resource..."
Add-ClusterResource -Name $capName -ResourceType "Network Name" -Group $groupName | Out-Null

# Step 6: Configure Network Name parameter
Write-Host "Configuring Network Name resource..."
Set-ClusterParameter -InputObject $capName -Name Name -Value $dnsName

# Verify configuration
Write-Host "Verifying Network Name configuration..."
Get-ClusterResource $capName | Get-ClusterParameter | Where-Object {$_.Name -eq 'Name'} | Format-Table Name, Value -AutoSize

# Step 7: Set dependency (Network Name depends on IP)
Write-Host "Setting resource dependencies..."
Set-ClusterResourceDependency -Resource $capName -Dependency "[$capName-IP]"

# Step 8: Bring the IP Address resource online first and verify
Write-Host "Bringing IP Address resource online..."
try {
    Start-ClusterResource -Name "$capName-IP" -ErrorAction Stop
    Start-Sleep -Seconds 2
    
    $ipState = (Get-ClusterResource "$capName-IP").State
    Write-Host "IP Address resource state: $ipState"
    
    if ($ipState -ne "Online") {
        Write-Error "IP Address resource failed to come online. Current state: $ipState"
        Write-Host "Checking configuration..."
        Get-ClusterResource "$capName-IP" | Get-ClusterParameter | Format-Table -AutoSize
        exit
    }
} catch {
    Write-Error "Failed to bring IP Address resource online: $_"
    Write-Host "Current IP resource configuration:"
    Get-ClusterResource "$capName-IP" | Get-ClusterParameter | Format-Table -AutoSize
    exit
}

# Step 9: Bring the Network Name resource online
Write-Host "Bringing Network Name resource online..."
try {
    Start-ClusterResource -Name $capName -ErrorAction Stop
    Start-Sleep -Seconds 2
    
    $nnState = (Get-ClusterResource $capName).State
    Write-Host "Network Name resource state: $nnState"
    
    if ($nnState -ne "Online") {
        Write-Warning "Network Name resource failed to come online. Current state: $nnState"
        Write-Host "`nTroubleshooting information:"
        Write-Host "1. Check DNS server is reachable from cluster nodes"
        Write-Host "2. Verify cluster nodes have permissions to create DNS records"
        Write-Host "3. Check Event Viewer > Windows Logs > System for FailoverClustering events"
        Write-Host "4. Verify the DNS name '$dnsName' doesn't already exist in DNS"
        Write-Host "`nTo view detailed error information, run:"
        Write-Host "Get-ClusterLog -TimeSpan 5 -Destination C:\ClusterLogs"
    }
} catch {
    Write-Error "Failed to bring Network Name resource online: $_"
    Write-Host "`nCommon causes:"
    Write-Host "- DNS registration failure (check DNS server accessibility)"
    Write-Host "- Computer object creation failure in Active Directory"
    Write-Host "- Network Name already exists in DNS or AD"
    Write-Host "- Cluster nodes lack permissions to update DNS/AD"
    Write-Host "`nCurrent Network Name configuration:"
    Get-ClusterResource $capName | Get-ClusterParameter | Format-Table -AutoSize
}

# Step 10: Bring the group online
Write-Host "`nStarting cluster group..."
Start-ClusterGroup -Name $groupName -ErrorAction SilentlyContinue

# Display final status
Write-Host "`n=== Final Status ==="
Get-ClusterGroup $groupName | Get-ClusterResource | Format-Table Name, State, ResourceType -AutoSize

$nnFinalState = (Get-ClusterResource $capName).State
if ($nnFinalState -eq "Online") {
    Write-Host "`nClient Access Point created successfully!" -ForegroundColor Green
    Write-Host "DNS Name: $dnsName"
    Write-Host "IP Address: $ipAddress"
} else {
    Write-Host "`nClient Access Point created but Network Name is not online." -ForegroundColor Yellow
    Write-Host "Please review the troubleshooting information above."
} 
