function Write-Log([string]$message) {
    $message | Tee-Object -FilePath C:\GcpSetupLog.txt -Append | Write-Output
}

function All-Instances-Ready {
  do {
    Write-Log "Checking if computer has joined a domain..."
    $InDomain = (Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain
    if ($InDomain -eq $true) {
      Write-Output "This computer has joined a domain, continuing"
      break
    }
    Start-Sleep -s 5
  } while ($true)

  %{ for node in [node_netbios_1, node_netbios_2, witness_netbios] }
  while ($true) {
    try {
      Write-Log "Waiting for node ${node} to be domain joined..."
      Get-ADComputer -Identity "${node}"
      break
    } catch {
      Start-Sleep -s 5
    }
  }
  %{ endfor }
}

function Wait-For-User {
  $dom = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
  $root = $dom.GetDirectoryEntry()
  $searcher = [ADSISearcher] $root
  $searcher.Filter = "(sAMAccountName=${cluster_user_name})"
  while ($null -eq $searcher.FindOne())
  {
    Write-Log "Waiting for Active Directory user for database: ${cluster_user_name}"
    Start-Sleep -s 10
  }
}

function Cluster-In-Domain {
  while ($true) {
    try {
      Write-Log "Waiting for cluster ${cluster_name} to be domain joined..."
      Get-ADComputer -Identity "${cluster_name}"
      break
    } catch {
      Start-Sleep -s 5
    }
  }
}

function Cluster-Ready {
  $ClusterName = "${cluster_name}"
  while ($true) {
    Write-Log "Waiting for cluster $ClusterName to appear..."
    try {
      $cluster = Get-Cluster
      $ret = ($cluster.Name -like $ClusterName)
      if ($ret -eq $true) {
        break
      }
    } catch {}
    Start-Sleep -s 10
  }
}

function Node-Up {
  while ($true) {
    Write-Log "Waiting for this node to be up in cluster..."
    try {
        $NodeStatus = Get-ClusterNode | Where-Object Name -eq $env:computername | Select State 
        if ($NodeStatus.State -eq "Up") {
            Write-Log "Current node is up, continuing..."
            break
        }
    } catch {}
    Start-Sleep -s 10
  }
}

# Function to get the primary network adapter
function Get-PrimaryNetworkAdapter {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$AdapterName = $null
    )
    
    if ($AdapterName) {
        try {
            $adapter = Get-NetAdapter -Name $AdapterName -ErrorAction Stop
            Write-Host "Using specified adapter: $($adapter.Name)"
            return $adapter
        }
        catch {
            Write-Warning "Specified adapter '$AdapterName' not found. Searching for primary adapter..."
        }
    }
    
    # Find the primary active network adapter
    $adapter = Get-NetAdapter | Where-Object { 
        $_.Status -eq "Up" -and 
        $_.Virtual -eq $false -and 
        $_.Name -notlike "*Loopback*" -and
        $_.Name -notlike "*Bluetooth*" -and
        $_.Name -notlike "*VMware*" -and
        $_.Name -notlike "*VirtualBox*"
    } | Select-Object -First 1
    
    if (-not $adapter) {
        throw "No suitable network adapter found"
    }
    
    Write-Host "Found primary network adapter: $($adapter.Name)"
    return $adapter
}

# Function to set static IP configuration
function Set-StaticIPConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$IPAddress,
        
        [Parameter(Mandatory)]
        [string]$SubnetMask,
        
        [Parameter(Mandatory)]
        [string]$Gateway,
        
        [Parameter()]
        [string]$AdapterName = $null,
        
        [Parameter()]
        [int]$PrefixLength = $null
    )
    
    try {
        # Get the network adapter
        $adapter = Get-PrimaryNetworkAdapter -AdapterName $AdapterName
        
        # Calculate prefix length from subnet mask if not provided
        if (-not $PrefixLength) {
            $PrefixLength = Get-PrefixLengthFromSubnetMask -SubnetMask $SubnetMask
        }
        
        Write-Host "Setting static IP configuration on adapter: $($adapter.Name)"
        Write-Host "  IP Address: $IPAddress"
        Write-Host "  Subnet Mask: $SubnetMask (/$PrefixLength)"
        Write-Host "  Gateway: $Gateway"
        
        # Remove existing IP configuration
        Write-Host "Removing existing IP configuration..."
        Remove-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -Confirm:$false -ErrorAction SilentlyContinue
        Remove-NetRoute -InterfaceIndex $adapter.InterfaceIndex -Confirm:$false -ErrorAction SilentlyContinue
        
        # Set new IP address
        Write-Host "Configuring new IP address..."
        New-NetIPAddress `
            -InterfaceIndex $adapter.InterfaceIndex `
            -IPAddress $IPAddress `
            -PrefixLength $PrefixLength `
            -DefaultGateway $Gateway
        
        Write-Host "Static IP configuration applied successfully."
        
    }
    catch {
        Write-Error "Failed to set static IP configuration: $($_.Exception.Message)"
        throw
    }
}

# Function to convert subnet mask to prefix length
function Get-PrefixLengthFromSubnetMask {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SubnetMask
    )
    
    $subnetMaskTable = @{
        "255.255.255.255" = 32
        "255.255.255.254" = 31
        "255.255.255.252" = 30
        "255.255.255.248" = 29
        "255.255.255.240" = 28
        "255.255.255.224" = 27
        "255.255.255.192" = 26
        "255.255.255.128" = 25
        "255.255.255.0"   = 24
        "255.255.254.0"   = 23
        "255.255.252.0"   = 22
        "255.255.248.0"   = 21
        "255.255.240.0"   = 20
        "255.255.224.0"   = 19
        "255.255.192.0"   = 18
        "255.255.128.0"   = 17
        "255.255.0.0"     = 16
        "255.254.0.0"     = 15
        "255.252.0.0"     = 14
        "255.248.0.0"     = 13
        "255.240.0.0"     = 12
        "255.224.0.0"     = 11
        "255.192.0.0"     = 10
        "255.128.0.0"     = 9
        "255.0.0.0"       = 8
    }
    
    if ($subnetMaskTable.ContainsKey($SubnetMask)) {
        return $subnetMaskTable[$SubnetMask]
    }
    else {
        throw "Invalid subnet mask: $SubnetMask"
    }
}

# Function to set DNS server configuration
function Set-DNSConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$DNSServers,
        
        [Parameter()]
        [string]$AdapterName = $null
    )
    
    try {
        # Get the network adapter
        $adapter = Get-PrimaryNetworkAdapter -AdapterName $AdapterName
        
        Write-Host "Setting DNS configuration on adapter: $($adapter.Name)"
        Write-Host "  Primary DNS: $($DNSServers[0])"
        if ($DNSServers.Count -gt 1) {
            Write-Host "  Secondary DNS: $($DNSServers[1])"
        }
        
        # Set DNS server addresses
        Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses $DNSServers
        
        # Flush DNS cache
        Write-Host "Flushing DNS cache..."
        Clear-DnsClientCache
        
        Write-Host "DNS configuration applied successfully."
        
    }
    catch {
        Write-Error "Failed to set DNS configuration: $($_.Exception.Message)"
        throw
    }
}

# Function to display current network configuration
function Show-NetworkConfiguration {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$AdapterName = $null
    )
    
    try {
        $adapter = Get-PrimaryNetworkAdapter -AdapterName $AdapterName
        
        Write-Host "`n=== Current Network Configuration ===" -ForegroundColor Green
        Write-Host "Adapter: $($adapter.Name)"
        Write-Host "Status: $($adapter.Status)"
        
        # Get IP configuration
        $ipConfig = Get-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
        if ($ipConfig) {
            Write-Host "IP Address: $($ipConfig.IPAddress)"
            Write-Host "Prefix Length: $($ipConfig.PrefixLength)"
        }
        
        # Get gateway
        $gateway = Get-NetRoute -InterfaceIndex $adapter.InterfaceIndex -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue
        if ($gateway) {
            Write-Host "Gateway: $($gateway.NextHop)"
        }
        
        # Get DNS servers
        $dnsServers = Get-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -AddressFamily IPv4
        if ($dnsServers.ServerAddresses) {
            Write-Host "DNS Servers: $($dnsServers.ServerAddresses -join ', ')"
        }
        
        Write-Host "======================================`n" -ForegroundColor Green
    }
    catch {
        Write-Warning "Could not retrieve network configuration: $($_.Exception.Message)"
    }
}

# Function to test network connectivity
function Test-NetworkConnectivity {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Gateway = "10.0.0.1",
        
        [Parameter()]
        [string]$DNSServer = "10.0.0.1",
        
        [Parameter()]
        [string]$ExternalHost = "8.8.8.8"
    )
    
    Write-Host "`n=== Testing Network Connectivity ===" -ForegroundColor Green
    
    # Test gateway connectivity
    Write-Host "Testing gateway connectivity ($Gateway)..."
    $gatewayTest = Test-NetConnection -ComputerName $Gateway -InformationLevel Quiet
    Write-Host "Gateway test: $(if ($gatewayTest) { 'PASS' } else { 'FAIL' })" -ForegroundColor $(if ($gatewayTest) { 'Green' } else { 'Red' })
    
    # Test DNS server connectivity
    Write-Host "Testing DNS server connectivity ($DNSServer)..."
    $dnsTest = Test-NetConnection -ComputerName $DNSServer -InformationLevel Quiet
    Write-Host "DNS server test: $(if ($dnsTest) { 'PASS' } else { 'FAIL' })" -ForegroundColor $(if ($dnsTest) { 'Green' } else { 'Red' })
    
    # Test external connectivity
    Write-Host "Testing external connectivity ($ExternalHost)..."
    $externalTest = Test-NetConnection -ComputerName $ExternalHost -InformationLevel Quiet
    Write-Host "External test: $(if ($externalTest) { 'PASS' } else { 'FAIL' })" -ForegroundColor $(if ($externalTest) { 'Green' } else { 'Red' })
    
    # Test DNS resolution
    Write-Host "Testing DNS resolution (google.com)..."
    try {
        $dnsResolution = Resolve-DnsName -Name "google.com" -ErrorAction Stop
        Write-Host "DNS resolution test: PASS" -ForegroundColor Green
    }
    catch {
        Write-Host "DNS resolution test: FAIL" -ForegroundColor Red
    }
    
    Write-Host "===================================`n" -ForegroundColor Green
}

# Main function to configure static IP and DNS
function Set-StaticNetworkConfiguration {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$IPAddress = "10.0.0.11",
        
        [Parameter()]
        [string]$SubnetMask = "255.255.255.0",
        
        [Parameter()]
        [string]$Gateway = "10.0.0.1",
        
        [Parameter()]
        [string[]]$DNSServers = @("10.0.0.1"),
        
        [Parameter()]
        [string]$AdapterName = $null,
        
        [Parameter()]
        [switch]$ShowConfig,
        
        [Parameter()]
        [switch]$TestConnectivity
    )
    
    try {
        Write-Host "=== Configuring Static Network Settings ===" -ForegroundColor Cyan
        
        if ($ShowConfig) {
            Write-Host "Current configuration:"
            Show-NetworkConfiguration -AdapterName $AdapterName
        }
        
        # Set static IP configuration
        Set-StaticIPConfiguration -IPAddress $IPAddress -SubnetMask $SubnetMask -Gateway $Gateway -AdapterName $AdapterName
        
        # Wait a moment for the IP configuration to settle
        Start-Sleep -Seconds 3
        
        # Set DNS configuration
        Set-DNSConfiguration -DNSServers $DNSServers -AdapterName $AdapterName
        
        Write-Host "`nNetwork configuration completed successfully!" -ForegroundColor Green
        
        # Show new configuration
        Show-NetworkConfiguration -AdapterName $AdapterName
        
        # Test connectivity if requested
        if ($TestConnectivity) {
            Test-NetworkConnectivity -Gateway $Gateway -DNSServer $DNSServers[0]
        }
        
    }
    catch {
        Write-Error "Failed to configure network settings: $($_.Exception.Message)"
        throw
    }
}
