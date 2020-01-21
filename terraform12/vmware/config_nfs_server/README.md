<!---
Copyright IBM Corp. 2019, 2019
--->

# Config NFS Server Module

Installs and configures NFS server for image registry storage (image-regisry operator). By default this is done on Infra node and the NFS folder is /var/nfs/registry.

## OS requirements

Supported On RHEL 7.x Linux

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| dependsOn | Boolean for dependency | string | `true` | no |
| nfs_drive | Drive that should be formatted and used as NFS | string | `/dev/sdb` | no |
| vm_ipv4_address_list | IPv4 address for vNIC configuration | list | - | yes |
| vm_os_password | Password for the Operating System User to access virtual machine | string | - | yes |
| vm_os_private_key |  | string | `` | no |
| vm_os_user | User for the Operating System User to access virtual machine | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| dependsOn | Output Parameter set when the module execution is completed |
