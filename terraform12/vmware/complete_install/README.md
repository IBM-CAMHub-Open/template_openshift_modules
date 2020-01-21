<!---
Copyright IBM Corp. 2019, 2019
--->

# Get console link and kubeadmin password 
This module waits for image registry to be set and retrieves the console link and kubeadmin password.

## OS requirements

Supported On RHEL 7.x Linux

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| vm_ipv4_address | IPv4 address for vNIC configuration | string | - | yes |
| vm_os_password | Password for the Operating System User to access virtual machine | string | - | yes |
| vm_os_private_key | Private key for Operating System User to access virtual machine | string | `` | no |
| vm_os_user | User for the Operating System User to access virtual machine | string | - | yes |
| dependsOn | Module depends variable to wait on. | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| console | OCP console URL |
| password | Base64 encoded kubeadmin password |
| dependsOn | Output Parameter set when the module execution is completed |