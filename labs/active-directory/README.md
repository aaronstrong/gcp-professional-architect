# Terraform Code to Deploy Microsoft Active Directory Domain Controllers

The code here deploys Microsoft Active Directory Domain Controllers including the network environment, and a test instance. You will need to manually configure and promote the domain controllers, and configure site replication.

## Architecture

![](https://cloud.google.com/architecture/images/configuring-microsoft-windows-dfs-on-gcp-extension.svg)

## Features

* Create the network environment including firewall rules.
* Use a Cloud DNS private forwarding zone to integrate Google Cloud's internal DNS with Active Directory DNS.
* Create two domain controllers in different zones.
* Deploy Compute Engine instance without external addresses and connect to it using IAP for TCP forwarding.
* Configure Active Directory Sites & Replication.

### Pre-requirements
* A GCP project must already exist
* IAP API must be enabled and appropriate IAM permissions to allow connectivity to the private test instance

## Create and configure a Windows Domain Controller

1. Create a VM with the terraform script to use as a domain controller.
1. Generate a password so that you can connect to the domain controller. Record the username and password for future use.

    ```bash
    gcloud compute reset-windows-password VM_NAME --zone=ZONE
    ```
    * replace `VM_NAME` with the name of the VM to change the password for.<br>
    * replace `ZONE` with the zone the VM was deployed into.
    >**Note**: Wait for the instance to fully come online. Use console port to track progress.

1. [Using RDP](https://cloud.google.com/compute/docs/instances/connecting-to-instance#windows), connect to the domain controller VM with your local account username and password.
1. Open up a PowerShell prompt with administrator privileges and set the local `Administrator` account password:
    ```bash
    net user Administrator *
    ```
1. Open up a [PowerShell prompt with administrator privileges](https://docs.microsoft.com/en-us/powershell/scripting/windows-powershell/starting-windows-powershell?view=powershell-7.1#with-administrative-privileges-run-as-administrator) and copy and paste the following syntax. Then run the script.
    ```bash
    $domainName = "contoso.local"
    $netbiosName = "contoso"
    $safeModeAdminstratorPassword = ConvertTo-SecureString 'BestCloud1!' -AsPlainText -Force
    $logpath = "C:\log\log.txt"
    $domainMode = "Win2012R2"
    $forestMode = "Win2012R2"

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
    ```

### Configure Active Directory Sites

1. After the instance has rebooted, RDP back into the instance.
1. Open up a [PowerShell prompt with administrator privileges](https://docs.microsoft.com/en-us/powershell/scripting/windows-powershell/starting-windows-powershell?view=powershell-7.1#with-administrative-privileges-run-as-administrator):
    ```bash
    New-ADReplicationSite -Name "GCP-us-central1" -Description "Site1"
    New-ADReplicationSite -Name "GCP-us-east1" -Description "Site2"
    ```

### Configure site links for Active Directory Replication

1. Open up a elevated PowerShell shell prompt:
    ```bash
    New-ADReplicationSiteLink -Name "GCP-us-central1-us-east1" -SitesIncluded GCP-us-central1,GCP-us-east1 -Cost 250 -ReplicationFrequencyInMinutes 15 -InterSiteTransportProtocol IP
    ```

### Configure Subnets for Active Directory Sites

1. Open up a elevated PowerShell shell prompt:
    ```bash
    New-ADReplicationSubnet -Name "10.0.0.0/24" -Site "GCP-us-central1"

    New-ADReplicationSubnet -Name "10.1.0.0/24" -Site "GCP-us-east1"
    ```

### Add `addc-1` to the appropriate site `GCP-us-central`

1. Open up a elevated PowerShell shell prompt:
    ```bash
    Move-ADDirectoryServer -Identity addc-1 -Site "GCP-us-central1"
    ```
## Promoting Additional Domain Controllers

### Configure addc-2 as a domain controller
1. Generate a new local password from the [previous steps](##Create-and-configure-a-Windows-Domain-Controller) and [RDP](https://cloud.google.com/compute/docs/instances/connecting-to-instance#windows) to the instance.
1. Open up a [PowerShell prompt with administrator privileges](https://docs.microsoft.com/en-us/powershell/scripting/windows-powershell/starting-windows-powershell?view=powershell-7.1#with-administrative-privileges-run-as-administrator):
    ```bash
    Import-Module ADDSDeployment
    Install-ADDSDomainController `
    -NoGlobalCatalog:$false `
    -CreateDnsDelegation:$false `
    -Credential (Get-Credential) `
    -CriticalReplicationOnly:$false `
    -DatabasePath "C:\Windows\NTDS" `
    -DomainName "contoso.local" `
    -InstallDns:$true `
    -LogPath "C:\Windows\NTDS" `
    -NoRebootOnCompletion:$false `
    -ReplicationSourceDC "addc-1.contoso.local" `
    -SiteName "GCP-us-east1" `
    -SysvolPath "C:\Windows\SYSVOL" `
    -Force:$true
    ```
    >**Note**: May need to set the local DNS setting to point to the IP address of addc-1.

## Testing the Configuration

1. Create a VM with the terraform script to use as a `test-vm`.
1. Generate a password so that you can connect to the domain controller. Record the username and password for future use.
    > Note: Wait for the instance to fully come online.
    ```bash
    gcloud compute reset-windows-password VM_NAME --zone=ZONE
    ```
### Connect to the `test-vm` instance

1. At your local command prompt, start a tunnel using IAP and the gcloud tool:
    ```
    gcloud beta compute start-iap-tunnel test-vm 3389 \
        --zone=zone \
        --project=project-id
    ```
    Where:<br>
    * zone is the zone in the us-central1 region where test-vm is deployed.
    * project-id is the project ID you chose for this tutorial.

### Join test vm to domain
1. Open an elevated PowerShell command prompt:
    ```bash
    Add-Computer -DomainName contoso.local -Restart
    ```


### Verify Domain Membership and the active controller
1. Wait a moment for the server to restart. The tunnel for RDP will still be active.
1. Reconnect to the instance using RDP, but this time enter domain administrator credentials, for example, example\administrator with the domain administrator password.
1. Verify the active domain controller by running the following command in a Command Prompt window:
    ```bash
    echo %LOGONSERVER%
    ```
    You see output similar to the following, identifying dc-1 as the active domain controller.

    ```bash
    \\addc-1
    ```
    If you're interested in exploring the DNS-based failover behavior of domain controllers, follow these steps:


    1. Sign out from `test-vm` (be sure to sign out, not simply disconnect).
    1. Stop `addc-1`, and then log in to `test-vm` again after `addc-1`stops.

    This next login might take longer than usual, but after logging in, if you rerun `echo %logonserver%`, you can see that `\\addc-2` has become the active domain controller.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_auto_restart"></a> [auto\_restart](#input\_auto\_restart) | Set if the instance should auto-restart. | `bool` | `false` | no |
| <a name="input_boot_disk"></a> [boot\_disk](#input\_boot\_disk) | What image the instance should boot from. | `string` | `"windows-cloud/windows-2019"` | no |
| <a name="input_cidr_range_1"></a> [cidr\_range\_1](#input\_cidr\_range\_1) | n/a | `string` | `"10.0.0.0/24"` | no |
| <a name="input_cidr_range_2"></a> [cidr\_range\_2](#input\_cidr\_range\_2) | n/a | `string` | `"10.1.0.0/24"` | no |
| <a name="input_dc_machine_type"></a> [dc\_machine\_type](#input\_dc\_machine\_type) | Machine type to deploy for the Domain Controller | `string` | `"e2-medium"` | no |
| <a name="input_preemptible"></a> [preemptible](#input\_preemptible) | Set if this instance should be preemptible | `bool` | `true` | no || <a name="input_prefix_hostname"></a> [prefix\_hostname](#input\_prefix\_hostname) | The hostname prefix | `string` | `"addc"` | no |     
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The project ID | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `"us-central1"` | no |
| <a name="input_static_ip"></a> [static\_ip](#input\_static\_ip) | The last octet in a static host ip address. | `number` | `2` | no |    

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_test-name"></a> [test-name](#output\_test-name) | The name of the first domain controller. |
| <a name="output_test-zone"></a> [test-zone](#output\_test-zone) | The zone the domain controller is deployed into. |


## References
* [Deploying Microsoft Active Domain Controllers with Advanced Networking Configuration on Google Cloud](https://cloud.google.com/architecture/deploying-microsoft-active-directory-domain-controllers-with-advanced-networking-configuration-on-gcp)
* [Microsoft SQL AlwaysOn Deployment](https://github.com/GoogleCloudPlatform/community/blob/master/tutorials/sql-server-ao-single-subnet/index.md)