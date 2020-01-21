<!---
Copyright IBM Corp. 2019, 2019
--->

# Install and Config Apache Web Server 

This module downloads, installs and configures Apache Web Server. This web server hosts the bootstrap, control and compute ignition files.

## OS requirements

Supported On RHEL 7.x Linux

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| vm_ipv4_address | IPv4 address for vNIC configuration | string | - | yes |
| vm_os_password | Password for the Operating System User to access virtual machine | string | - | yes |
| vm_os_private_key |  | string | `` | no |
| vm_os_user | User for the Operating System User to access virtual machine | string | - | yes |
| dependsOn | Module depends variable to wait on. | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| dependsOn | Output Parameter set when the module execution is completed |
