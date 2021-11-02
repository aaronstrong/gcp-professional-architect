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
<!-- 1. Connect to the instance
    1. For username, enter `contoso.local\administrator`.
    1. For password, enter the password you previously assigned.
1. In **Server Manager** select the menu item **Tools > Active Directory Sites and Services**.
1. In the left-hand navigation pane, under **Active Directory Sites and Services**, right-click **Sites** and then select **New Site**.
1. For **Name**, enter `GCP-us-central1`.
1. Under **Select a site link object for this site**, select `DEFAULTIPSITELINK`.
1. Click **OK** twice.
1. Repeat steps 3-6 to create a similar site named `GCP-us-east1`. -->

### Configure site links for Active Directory Replication

1. Open up a elevated PowerShell shell prompt:
    ```bash
    New-ADReplicationSiteLink -Name "GCP-us-central1-us-east1" -SitesIncluded GCP-us-central1,GCP-us-east1 -Cost 250 -ReplicationFrequencyInMinutes 15 -InterSiteTransportProtocol IP
    ```
<!-- 1. In the left-hand navigation pane, under Active Directory Sites and Services > Sites, expand Inter-Site Transports.
1. Right-click IP, and then choose New Site Link.
1. For Name, specify `GCP-us-central1-us-east1`.
1. Under Sites not in this site link, highlight both `GCP-us-central1` and `GCP-us-east1`.
1. Click **Add** to move the sites into **Sites in this site link**.
1. Click **OK**.
1. In the left-hand navigation pane, under **Active Directory Sites and Services > Sites > Inter-Site Transports**, select **IP**.
1. Right-click the new site link `GCP-us-central1-us-east1`, and then choose **Properties**.
1. For Cost, enter 250.
   >Note: This cost is chosen to be a multiple of the ping time between domain controllers. In testing, the average ping time between dc-1 and dc-2 was 25 milliseconds. We multiplied this value by 10 to arrive at the cost. In more complex site topologies, using a meaningful measure such as ping time can help with domain controller selection, for example, if a failure occurs that requires selection of a domain controller in a remote site.
1. For **Replicate Every**, enter `15` minutes.
1. Click **OK**. -->

### Configure Subnets for Active Directory Sites

1. Open up a elevated PowerShell shell prompt:
    ```bash
    New-ADReplicationSubnet -Name "10.0.0.0/24" -Site "GCP-us-central1"

    New-ADReplicationSubnet -Name "10.1.0.0/24" -Site "GCP-us-east1"
    ```
<!-- 1. In the left-hand navigation pane, under Active Directory Sites and Services > Sites, right-click Subnets, and then select New Subnet.
1. For Prefix, enter 10.0.0.0/24.
1. Under Site Name, select GCP-us-central1.
1. Click OK.
1. Repeat steps 1–4 to create a similar subnet for 10.1.0.0/24 and site GCP-us-east1. -->

### Add `addc-1` to the appropriate site `GCP-us-central`

1. Open up a elevated PowerShell shell prompt:
    ```bash
    Move-ADDirectoryServer -Identity addc-1 -Site "GCP-us-central1"
    ```
<!-- 1. In the left-hand navigation pane, under Active Directory Sites and Services > Sites, expand Default-First-Site-Name > Servers, and expand GCP-us-central1.
1. Drag dc-1 from Default-First-Site-Name > Servers to GCP-us-central1 > Servers.
1. In the Active Directory Domain Services confirmation dialog, click Yes.
    > Note: You just manually moved dc-1 into the site Google Cloud-us-central1 because when you promoted dc-1 to a domain controller, you hadn't yet created the Google Cloud sites. -->

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
<!-- 
1. Click the Notifications flag icon at the top of the Server Manager window.
1. In the Post-deployment Configuration notification, click Promote this server to a domain controller.
1. In the Active Directory Domain Services Configuration Wizard, under Select the deployment operation, choose Add a domain controller to an existing domain.
1. For Domain, enter `contoso.local`.
1. Under Supply the credentials to perform this operation, click Change.
1. In the Windows Security dialog, specify your domain administrator credentials:
    1. For **Username**, enter `contos\administrator`.
    1. For **Password**, enter the password you previously assigned to the local administrator account on `dc-1`.
1. Click **OK** to close the dialog.
1. Click **Next**.
1. In the **Domain Controller** Options page, under **Site name**, verify that `GCP-us-east1` is selected.
    >Note: As you promote dc-2 to a domain controller, because you've defined Google Cloud-specific sites and their associated subnets, dc-2 automatically selects the appropriate site, `GCP-us-east1`, based on its network address.
1. Enter and confirm a strong password for the Directory Services Restore Mode (DSRM) password.
1. You can use the same DSRM password that you specified for dc-1. In any case, remember this password. It can be useful if you need to repair or recover your domain.
1. Click **Next**.
1. In the **DNS Options** page, click **Next**.
    You might see the warning, A delegation for this DNS server cannot be created because the authoritative parent zone cannot be found. You can disregard this warning because the forwarding zone in the preceding Cloud DNS configuration serves the same purpose as the delegation mentioned in the warning.
1. In the Additional Options page, click **Next**.
1. In the Paths page, click **Next**.
1. In the Review Options page, click **Next**.
1. In the Prerequisites Check page, after the checks complete, click **Install**.
   >Note: Because the instance automatically restarts after installation, you are disconnected from your RDP session. -->

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
    gcloud beta compute start-iap-tunnel test-1 3389 \
        --zone=zone \
        --project=project-id
    ```
    Where:<br>
    * zone is the zone in the us-central1 region where test-1 is deployed.
    * project-id is the project ID you chose for this tutorial.

### Join test vm to domain
1. Open an elevated PowerShell command prompt:
    ```bash
    Add-Computer -DomainName contoso.local -Restart
    ```
<!-- 1. In the Remote Desktop window, join the instance to the example.org domain. Click Local Server in the left-hand navigation pane of the Server Manager window.
1. Under Properties For test-1, click the WORKGROUP link.
1. On the Computer Name tab of the System Properties dialog, click Change.
1. In the Member of section, select Domain, and then enter example.org.
1. Click OK.
1. When prompted for credentials, specify example\administrator along with the previously chosen domain administrator password, and click OK.
1. Click OK, OK, Close, and finally **Restart Now**. -->

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


    1. Sign out from `vm-test` (be sure to sign out, not simply disconnect).
    1. Stop `addc-1`, and then log in to `vm-test` again after `addc-1`stops.

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