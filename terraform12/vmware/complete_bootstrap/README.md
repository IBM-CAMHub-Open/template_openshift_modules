<!---
Copyright IBM Corp. 2019, 2019
--->

# Complete bootstrap process
This module waits for worker nodes to come up and accept all the CSRs 

## OS requirements

Supported On RHEL 7.x Linux

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| vm_ipv4_address | IPv4 address for vNIC configuration | string | - | yes |
| vm_os_password | Password for the Operating System User to access virtual machine | string | - | yes |
| vm_os_private_key | Private key for Operating System User to access virtual machine | string | `` | no |
| vm_os_user | User for the Operating System User to access virtual machine | string | - | yes |
| ocp_domain | OCP cluster domain name | string | - | yes |
| ocp_cluster_name | OCP cluster name | string | - | yes |
| number_nodes | Total number of OCP cluster nodes | string | - | yes |
| dependsOn | Module depends variable to wait on. | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| dependsOn | Output Parameter set when the module execution is completed |