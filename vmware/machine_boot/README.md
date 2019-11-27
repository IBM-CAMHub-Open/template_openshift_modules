<!---
Copyright IBM Corp. 2019, 2019
--->

# Create OCP Cluster Virtual Machines

Creates boostrap, control and compute nodes using the ignition files.

## OS requirements

Supported On RHCOS 4.2

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| name | Name of the VM | string |  | yes |
| instance_count | Number of VMs | string | | yes |
| ignition | Ignition files | list | | yes |
| resource_pool_id | VMware resource pool | string | | yes |
| folder | VMware folder | string | | yes |
| datastore | VMware datastore | string | | yes |
| network | VMware network adapter | string | | yes |
| datacenter_id | VMware data center ID | string | | yes |
| template | Location of RHCOS template | string | | yes |
| memory | Node memory. Varies on node type. | string | | yes |
| cpu | Node CPU. Varies on node type. | string | | yes |
| disk_size | Node Disk Size. Varies on node type. | string | | yes |
| wait_for_guest_net_timeout | Timeout time to wait for node to come up | string | 5mns | yes |
| dependsOn | Boolean for dependency | string | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| ip | IP of the node (list) |
| name | Node name (list) |
| dependsOn | Output Parameter set when the module execution is completed |
