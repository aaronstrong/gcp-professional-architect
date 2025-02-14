# Get the primary network adapter
$Adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.InterfaceDescription -notmatch "VPN" } | Select-Object -First 1

if ($Adapter) {
    $InterfaceAlias = $Adapter.Name
    
    # Get IP address and subnet mask
    $NetIPConfig = Get-NetIPAddress -InterfaceAlias $InterfaceAlias -AddressFamily IPv4
    $IPAddress = $NetIPConfig.IPAddress
    $PrefixLength = $NetIPConfig.PrefixLength
    
    # Convert PrefixLength to Subnet Mask
    $SubnetMask = [System.Net.IPAddress]::Parse(("1" * $PrefixLength).PadRight(32, "0"), 2).ToString()
    
    # Get default gateway
    $DefaultGateway = (Get-NetRoute -InterfaceAlias $InterfaceAlias | Where-Object { $_.DestinationPrefix -eq "0.0.0.0/0" }).NextHop
    
    # Get DNS servers
    $DNSServers = (Get-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -AddressFamily IPv4).ServerAddresses
    
    # Extract first three octets
    $Octets = $IPAddress -split "\."
    $NetworkPrefix = "$($Octets[0]).$($Octets[1]).$($Octets[2])"
    
    # Find an available IP in the range 0-100
    $NewIP = $null
    for ($i = 0; $i -lt 100; $i++) {
        $RandomOctet = Get-Random -Minimum 0 -Maximum 101
        $TestIP = "$NetworkPrefix.$RandomOctet"
        if (!(Test-Connection -ComputerName $TestIP -Count 1 -Quiet)) {
            $NewIP = $TestIP
            break
        }
    }
    
    if (-not $NewIP) {
        Write-Host "No available IP found in the range. Exiting..." -ForegroundColor Red
        exit
    }
    
    # Set static IP address
    New-NetIPAddress -InterfaceAlias $InterfaceAlias -IPAddress $NewIP -PrefixLength $PrefixLength -DefaultGateway $DefaultGateway -ErrorAction Stop
    
    # Set DNS servers (First: 127.0.0.1, Second: Previous DNS)
    Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddresses @("127.0.0.1", $DNSServers[0]) -ErrorAction Stop
    
    # Display results
    Write-Host "IP Address: $IPAddress"
    Write-Host "Subnet Mask: $SubnetMask"
    Write-Host "Default Gateway: $DefaultGateway"
    Write-Host "DNS Servers: 127.0.0.1, $($DNSServers -join ", ")"
    Write-Host "Assigned Static IP: $NewIP"
} else {
    Write-Host "No active network adapter found." -ForegroundColor Red
}
