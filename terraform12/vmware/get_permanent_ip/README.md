<!---
Copyright IBM Corp. 2019, 2020
--->

# Gets DHCP assigned IPv4 for control and compute node

This module must be used to retrieve the DHCP assigned IPv4 for control and compute node. 
The motivation for the module is, if we use default_ip_address to get the IPv4 for control and compute node
we may end up retrieving the OCP internal 10.x or 172.x IPs instead of DHCP assigned 192.168.1.x IPs.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| vm_ipv4_address | IPv4 address for vNIC configuration | string | - | yes |
| vm_os_password | Password for the Operating System User to access virtual machine | string | - | yes |
| vm_os_private_key | Private key for Operating System User to access virtual machine | string | `` | no |
| vm_os_user | User for the Operating System User to access virtual machine | string | - | yes |
| compute_nodes | Number of compute nodes | string | 2 | yes |
| control_nodes | Number of control nodes | string | 3 | yes |
| get_type | Which node IP to get. Valid values are all,compute,control | string | all | yes |
| dependsOn | Module depends variable to wait on. | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| control_ip | OCP control IPv4 |
| compute_ip | OCP compute IPv4 |
| dependsOn | Output Parameter set when the module execution is completed |
