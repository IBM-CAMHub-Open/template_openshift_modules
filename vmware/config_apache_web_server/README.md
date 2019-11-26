<!---
Copyright IBM Corp. 2019, 2019
--->

# Config Apache Web Server Module

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| vm_ipv4_address | IPv4 address for vNIC configuration | string | - | yes |
| vm_os_password | Password for the Operating System User to access virtual machine | string | - | yes |
| vm_os_private_key |  | string | `` | no |
| vm_os_user | User for the Operating System User to access virtual machine | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| dependsOn | Output Parameter when Module Complete |
