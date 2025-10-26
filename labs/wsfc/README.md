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
| <a name="output_private_addresses"></a> [private\_addresses](#output\_private\_addresses) | List of private addresses and assigned instances |
| <a name="output_public_ip_active_directory"></a> [public\_ip\_active\_directory](#output\_public\_ip\_active\_directory) | The public ip assigned to the active directory instance |
<!-- END_TF_DOCS -->
## References
* [Running Windows Server Failover Clustering](https://cloud.google.com/compute/docs/tutorials/running-windows-server-failover-clustering)
* [Configuring a SQL server failover cluster instances that uses Storage Spaces Direct](https://cloud.google.com/compute/docs/instances/sql-server/configure-failover-cluster-instance)
* [SQL Server Always On Groups Blueprint](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/tree/v43.0.0/blueprints/data-solutions/sqlserver-alwayson)
