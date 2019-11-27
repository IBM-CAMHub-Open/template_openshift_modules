<!---
Copyright IBM Corp. 2019, 2019
--->

# Monitor control plane bootstrap process
This module monitors control plane bootstrap process. 

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| vm_ipv4_address | IPv4 address for vNIC configuration | string | - | yes |
| vm_os_password | Password for the Operating System User to access virtual machine | string | - | yes |
| vm_os_private_key | Private key for Operating System User to access virtual machine | string | `` | no |
| vm_os_user | User for the Operating System User to access virtual machine | string | - | yes |
| boot_ipv4_address | Boot node IP address | string | - | yes |
| dependsOn | Module depends variable to wait on. | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| dependsOn | Output Parameter set when the module execution is completed |