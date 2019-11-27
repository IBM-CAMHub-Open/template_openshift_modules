<!---
Copyright IBM Corp. 2019, 2019
--->

# Configure OCP Image Registry

This module creates storage class and persistent volume using the NFS folder /var/nfs/registry on infra node.
Then it configures the image registry to use the configured persistent volume to as image registry.

## OS requirements

Supported On RHEL 7.x Linux

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| vm_ipv4_address | IPv4 address for vNIC configuration | string | - | yes |
| vm_os_password | Password for the Operating System User to access virtual machine | string | - | yes |
| vm_os_private_key |  | string | `` | no |
| vm_os_user | User for the Operating System User to access virtual machine | string | - | yes |
| nfs_ipv4_address | IP of NFS server. By default uses intra node as NFS server | string | - | yes |
| nfs_path | Path to NFS folder. | string | /var/nfs/registry | yes |
| dependsOn | Module depends variable to wait on. | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| dependsOn | Output Parameter set when the module execution is completed |
