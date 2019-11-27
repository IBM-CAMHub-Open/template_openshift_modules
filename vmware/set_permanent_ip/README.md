<!---
Copyright IBM Corp. 2019, 2019
--->

# Sets permanent IP based on MAC in dnsmasq

This module must be used to persist the IP of OCP cluster nodes based on generated MAC after cluster is up and running.
This ensures DHCP always returns the same IP. 

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| vm_ipv4_address | IPv4 address for vNIC configuration | string | - | yes |
| vm_os_password | Password for the Operating System User to access virtual machine | string | - | yes |
| vm_os_private_key | Private key for Operating System User to access virtual machine | string | `` | no |
| vm_os_user | User for the Operating System User to access virtual machine | string | - | yes |
| cluster_ipv4_addresses | Comma separated IPv4 address for OCP cluster nodes vNIC configuration | string | - | yes |
| dependsOn | Module depends variable to wait on. | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| dependsOn | Output Parameter set when the module execution is completed |