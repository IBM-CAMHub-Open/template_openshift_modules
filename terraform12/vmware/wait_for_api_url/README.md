<!---
Copyright IBM Corp. 2019, 2019
--->

# Wait for API URL
This module waits for worker or master machine config API URLs to be available. 
Once available the master or worker ignition is downloaded and copied over to the Infra node http server.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| vm_ipv4_address | IPv4 address for vNIC configuration | string | - | yes |
| vm_os_password | Password for the Operating System User to access virtual machine | string | - | yes |
| vm_os_private_key | Private key for Operating System User to access virtual machine | string | `` | no |
| vm_os_user | User for the Operating System User to access virtual machine | string | - | yes |
| ocp_domain | OCP cluster domain name | string | - | yes |
| ocp_cluster_name | OCP cluster name | string | - | yes |
| api_type | API type to wait for. Valid values are master or worker. | string |  | yes |
| dependsOn | Module depends variable to wait on. | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| dependsOn | Output Parameter set when the module execution is completed |