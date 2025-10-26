# Terraform Code to Windows Server Failover Cluster

The code here deploys a failover cluster using Windows Server on Google Cloud.

## Architecture

![](https://cloud.google.com/static/compute/docs/tutorials/images/failover-clustering-architecture.svg)

The code in this repo will deploy the following:

* A two node cluster running in GCP
* An Active Directory domain controller will be deployed

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
>Note: The Windows instances take some time to boot up and run the startup script. Look at the serial port output to check on the status.
1. Generate a password so that you can connect to the domain controller. Record the username and password for future use.

    ```bash
    gcloud compute reset-windows-password VM_NAME --zone=ZONE --project=my-project-id
    ```
    * replace `VM_NAME` with the name of the VM to change the password for.<br>
    * replace `ZONE` with the zone the VM was deployed into.
    * replace `project` with the correct project id
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

    # Install Module
    Install-WindowsFeature -Name RSAT-AD-PowerShell

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
    New-ADReplicationSite -Name "on-prem-location" -Description "Site1"
    New-ADReplicationSite -Name "GCP-us-central1" -Description "Site2"
    ```

### Configure site links for Active Directory Replication

1. Open up a elevated PowerShell shell prompt:
    ```bash
    New-ADReplicationSiteLink -Name "on-prem-GCP-us-central1" -SitesIncluded on-prem-location,GCP-us-central1 -Cost 250 -ReplicationFrequencyInMinutes 15 -InterSiteTransportProtocol IP
    ```

### Configure Subnets for Active Directory Sites

1. Open up a elevated PowerShell shell prompt:
    ```bash
    New-ADReplicationSubnet -Name "10.0.0.0/16" -Site "GCP-us-central1"

    New-ADReplicationSubnet -Name "192.168.0.0/24" -Site "on-prem-location"
    ```

### Add `test-us-central1-dc-01` to the appropriate site `GCP-us-central`

1. Open up a elevated PowerShell shell prompt:
    ```bash
    Move-ADDirectoryServer -Identity test-us-central1-dc-01 -Site "GCP-us-central1"
    ```
## Promoting Additional Domain Controllers

### Configure test-us-east1-dc-01 as a domain controller
1. Generate a new local password from the [previous steps](##Create-and-configure-a-Windows-Domain-Controller) and [RDP](https://cloud.google.com/compute/docs/instances/connecting-to-instance#windows) to the instance.
1. Join the `us-east1` instance to the domain. 
1. After the reboot, open up a [PowerShell prompt with administrator privileges](https://docs.microsoft.com/en-us/powershell/scripting/windows-powershell/starting-windows-powershell?view=powershell-7.1#with-administrative-privileges-run-as-administrator):
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
    -ReplicationSourceDC "test-us-central1-dc-01.contoso.local" `
    -SiteName "GCP-us-east1" `
    -SysvolPath "C:\Windows\SYSVOL" `
    -Force:$true
    ```
    >**Note**: May need to set the local DNS setting to point to the IP address of the first domain controller.

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
1. Leave `gcloud` running and open Microsoft Windows Remote Desktop Connection app.
1. Enter the tunnel endpoing as computer name:
    ```gcloud
    localhost:[local_port]
    ```

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
    \\dc-01
    ```
    If you're interested in exploring the DNS-based failover behavior of domain controllers, follow these steps:


    1. Sign out from `test-vm` (be sure to sign out, not simply disconnect).
    1. Stop `addc-1`, and then log in to `test-vm` again after `addc-1`stops.

    This next login might take longer than usual, but after logging in, if you rerun `echo %logonserver%`, you can see that `\\addc-2` has become the active domain controller.
<!-- BEGIN_TF_DOCS -->

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_AdDnsDomain"></a> [AdDnsDomain](#input\_AdDnsDomain) | Active Directory domain (FQDN) | `string` | `"contoso.local"` | no |
| <a name="input_AdNetbiosDomain"></a> [AdNetbiosDomain](#input\_AdNetbiosDomain) | Active Directory domain (NetBIOS) | `string` | `"CLOUD"` | no |
| <a name="input_auto_restart"></a> [auto\_restart](#input\_auto\_restart) | Set if the instance should auto-restart. | `bool` | `false` | no |
| <a name="input_boot_disk"></a> [boot\_disk](#input\_boot\_disk) | What image the instance should boot from. | `string` | `"windows-cloud/windows-2019"` | no |
| <a name="input_cidr_prefix"></a> [cidr\_prefix](#input\_cidr\_prefix) | Must be given in CIDR notation. The assigned supernet. | `string` | `"10.0.0.0/15"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Windows server failover cluster name | `string` | `"testcluster"` | no |
| <a name="input_cluster_password"></a> [cluster\_password](#input\_cluster\_password) | The password used by the default `cluster-admin` Active Diretory | `string` | `"Password1"` | no |
| <a name="input_cluster_username"></a> [cluster\_username](#input\_cluster\_username) | The Active Directory name to be used by the WSFC cluster. | `string` | `"cluster-admin"` | no |
| <a name="input_dc_machine_type"></a> [dc\_machine\_type](#input\_dc\_machine\_type) | Machine type to deploy for the Domain Controller | `string` | `"e2-medium"` | no |
| <a name="input_default_app_port"></a> [default\_app\_port](#input\_default\_app\_port) | WSFC default application port | `string` | `"59998"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment | `string` | `"test"` | no |
| <a name="input_list_instances"></a> [list\_instances](#input\_list\_instances) | Map of instances and their properties | <pre>map(object({<br/>    name         = string<br/>    machine_type = string<br/>    zone         = string<br/>    preemptible  = string<br/>  }))</pre> | <pre>{<br/>  "wsfc1": {<br/>    "machine_type": "e2-standard-2",<br/>    "name": "wsfc-1",<br/>    "preemptible": false,<br/>    "zone": "b"<br/>  },<br/>  "wsfc2": {<br/>    "machine_type": "e2-standard-2",<br/>    "name": "wsfc-2",<br/>    "preemptible": false,<br/>    "zone": "c"<br/>  }<br/>}</pre> | no |
| <a name="input_list_reserved_ips"></a> [list\_reserved\_ips](#input\_list\_reserved\_ips) | Map of reserved IPs to be created. Address is the last octet in the CIDR | <pre>map(object({<br/>    name    = string<br/>    address = string<br/><br/>  }))</pre> | <pre>{<br/>  "cluster_ip": {<br/>    "address": 8,<br/>    "name": "reserved-cluster-ip"<br/>  },<br/>  "dc1": {<br/>    "address": 6,<br/>    "name": "reserved-addc1"<br/>  },<br/>  "loadbalancer": {<br/>    "address": 9,<br/>    "name": "reserved-ilb"<br/>  },<br/>  "wsfc1": {<br/>    "address": 4,<br/>    "name": "reserved-wsfc-1"<br/>  },<br/>  "wsfc2": {<br/>    "address": 5,<br/>    "name": "reserved-wsfc-2"<br/>  }<br/>}</pre> | no |
| <a name="input_managed_ad_dn"></a> [managed\_ad\_dn](#input\_managed\_ad\_dn) | Managed Active Directory domain (eg. OU=Cloud,DC=example,DC=com). | `string` | `"DC=contoso,DC=local"` | no |
| <a name="input_preemptible"></a> [preemptible](#input\_preemptible) | Set if this instance should be preemptible | `bool` | `true` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The project ID | `string` | n/a | yes |
| <a name="input_project_services"></a> [project\_services](#input\_project\_services) | API services to enable | `list(any)` | <pre>[<br/>  "dns.googleapis.com",<br/>  "secretmanager.googleapis.com",<br/>  "compute.googleapis.com"<br/>]</pre> | no |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `"us-central1"` | no |
| <a name="input_secret_id"></a> [secret\_id](#input\_secret\_id) | Name of the Secret. Note: not the actual password | `string` | `"ad-password"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_account"></a> [cluster\_account](#output\_cluster\_account) | The Acitve Directory account for cluster setup |
| <a name="output_private_addresses"></a> [private\_addresses](#output\_private\_addresses) | n/a |
| <a name="output_public_ip_active_directory"></a> [public\_ip\_active\_directory](#output\_public\_ip\_active\_directory) | The public ip assigned to the active directory instance |
<!-- END_TF_DOCS -->
## References
* [Running Windows Server Failover Clustering](https://cloud.google.com/compute/docs/tutorials/running-windows-server-failover-clustering)
* [Configuring a SQL server failover cluster instances that uses Storage Spaces Direct](https://cloud.google.com/compute/docs/instances/sql-server/configure-failover-cluster-instance)
* [SQL Server Always On Groups Blueprint](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/tree/v43.0.0/blueprints/data-solutions/sqlserver-alwayson)
