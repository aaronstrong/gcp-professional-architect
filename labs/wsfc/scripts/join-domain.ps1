
${functions}


$ErrorActionPreference = "Stop"
$InitialSetup = 'c:\InitialSetupDone.txt'


#
# Read configuration from metadata.
#
Import-Module "$${Env:ProgramFiles}\Google\Compute Engine\sysprep\gce_base.psm1"

$ActiveDirectoryDnsDomain     = Get-MetaData -Property "attributes/ActiveDirectoryDnsDomain" -instance_only
$ActiveDirectoryNetbiosDomain = Get-MetaData -Property "attributes/ActiveDirectoryNetbiosDomain" -instance_only
$ProjectId                    = Get-MetaData -Property "project-id" -project_only
$Hostname                     = Get-MetaData -Property "hostname" -instance_only
$AccessToken                  = (Get-MetaData -Property "service-accounts/default/token" | ConvertFrom-Json).access_token





# Configuration
$domainName = "${ad_domain}"
$domainUsername = "administrator"
$projectId = $ProjectId         # Replace with your GCP project ID
$accessToken = $AccessToken     # Replace with your GCP access token

#
# Read the DSRM password from Secret Manager
#
$Secret = (Invoke-RestMethod `
    -Headers @{
        "Metadata-Flavor" = "Google";
        "x-goog-user-project" = $projectId;
        "Authorization" = "Bearer $accessToken"
    } `
    -Uri "https://secretmanager.googleapis.com/v1/projects/$projectId/secrets/${secret_id}/versions/latest:access")

$DsrmPassword = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Secret.payload.data))
$securePassword = ConvertTo-SecureString -AsPlainText $DsrmPassword -Force

# Build credential object
$credential = New-Object System.Management.Automation.PSCredential ("$domainName\$domainUsername", $securePassword)

# Check if already part of a domain
$computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object Name, Domain, DomainRole, PartOfDomain


if ($computerSystem.PartOfDomain -eq $true) {
    Write-Host "This computer is already part of the domain: $($computerSystem.Domain)" -ForegroundColor Green

    Write-Host "Checking all instances..."
    All-Instances-Ready

if ($env:computername -eq "${node_netbios_1}") {
      $SetupScript = @'
$dom = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
$root = $dom.GetDirectoryEntry()
$searcher = [ADSISearcher] $root
$searcher.Filter = "(sAMAccountName=${cluster_user_name})"
if ($null -eq $searcher.FindOne())
{
  $Secret = gcloud --quiet secrets versions access latest --secret="${cluster_admin_password_secret}"
  $Password = ConvertTo-SecureString $Secret -AsPlainText -Force
  Write-Output "Adding domain user: ${cluster_user_name}"
  New-ADUser -Name "${cluster_user_name}" -Description "SQL Admin account" -AccountPassword $Password -Enabled $true -PasswordNeverExpires $true ${managed_ad_dn_path}
}
try {
  Get-ADComputer -Identity "${cluster_name}"
} catch {
  Write-Output "Creating cluster: ${cluster_full} (NB: ${cluster_name})"
  New-Cluster -Name ${cluster_full} -Node ${node_netbios_1},${node_netbios_2} -NoStorage -StaticAddress ${cluster_ip}
  Start-Sleep -s 45
%{ if managed_ad_dn != "" }
    
  Write-Output "Adding ${cluster_name}$ to Computers"
  Add-ADGroupMember -Identity Computers -Members ${cluster_name}$
%{ endif }
}
'@
      $InitializeClusterScript = "C:\InitializeCluster.ps1"
      Write-Log "Writing initial setup script to $InitializeClusterScript"
      $SetupScript | Out-File -FilePath $InitializeClusterScript
      
      $securePassword = ConvertTo-SecureString "${cluster_admin_password_secret}" -AsPlainText -Force
      $cred = New-Object System.Management.Automation.PSCredential("${ad_domain}\${cluster_user_name}", $securePassword)

      Start-Process powershell -Credential $cred -ArgumentList "-ExecutionPolicy Bypass -File `"C:\InitializeCluster.ps1`"" -Wait
    

    
    
    
#     try{
#         Get-ADComputer -Identity "${cluster_name}"
#     } catch {
#         Write-Output "Creating cluster: ${cluster_full} (NB: ${cluster_name})"
#         New-Cluster -Name ${cluster_full} -Node ${node_netbios_1},${node_netbios_2} -NoStorage -StaticAddress ${cluster_ip}

#         Write-Output "Sleeping for 45 seconds ..."
#         Start-Sleep -s 45

#         Write-Output "Adding ${cluster_name} to Computers"
#         Add-ADGroupMember -Identity Computers -Members ${cluster_name}$
#     }
  }





    Write-host "Waiting for User..."
    Wait-For-User


    Write-host "Waiting for Cluster..."
    Cluster-Ready


    # Wait for other node to finish
    Start-Sleep -s 30

    if ($env:computername -eq "${node_netbios_1}") {    
      $Quorum = Get-ClusterQuorum 
      if ($Quorum.QuorumResource.State -ne "Online") {
          while ($true) {
              try { 
                  Write-Log "Turning on witness quorum in cluster..."
                  Set-ClusterQuorum -FileShareWitness \\${witness_netbios}\QWitness
                  break
              } catch {}
              Start-Sleep -s 5
          }
      }
    }


    Write-Log "Setup finished completely."
    New-Item $InitialSetup


} else {
    # Wait for domain to become available
    do {
        Write-Host "Waiting for domain '$ActiveDirectoryDnsDomain' to become available..." -ForegroundColor Yellow
        ipconfig /flushdns | Out-Null
        nltest /dsgetdc:$ActiveDirectoryDnsDomain | Out-Null
        $nltestExitCode = $LASTEXITCODE

        if ($nltestExitCode -ne 0) {
            Write-Host "Domain not available yet. Retrying in 15 seconds..." -ForegroundColor DarkYellow
            Start-Sleep -Seconds 15
        }
    } while ($nltestExitCode -ne 0)

    Write-Host "Domain '$ActiveDirectoryDnsDomain' is now available." -ForegroundColor Green

    # Proceed to domain join
    try {
        Write-Host "Attempting to join domain $domainName..." -ForegroundColor Yellow

        Add-Computer -DomainName $domainName -Credential $credential -ErrorAction Stop

        Write-Host "Successfully joined the domain. Restarting computer..." -ForegroundColor Green
        Restart-Computer -Force
    } catch {
        Write-Error "Failed to join domain: $_"
    }
}
