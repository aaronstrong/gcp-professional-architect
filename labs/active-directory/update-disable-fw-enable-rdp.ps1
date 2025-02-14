# Disable Windows Firewall for all profiles
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

# Enable Remote Desktop
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0

# Allow RDP in Windows Firewall
Enable-NetFirewallRule -Group "Remote Desktop"

# Ensure Network Level Authentication (NLA) is enabled for security
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "UserAuthentication" -Value 1

Write-Host "Windows Firewall is turned off and RDP is enabled." -ForegroundColor Green
