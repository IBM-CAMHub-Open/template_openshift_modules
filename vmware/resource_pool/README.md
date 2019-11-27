<!---
Copyright IBM Corp. 2019, 2019
--->

# Create VMware resource pool for OCP cluster nodes

Create a resource pool. Name of the pool must match the OCP cluster name.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| name | Pool name | string |  | yes |
| datacenter_id | VMware DC ID | string | | yes |
| vsphere_cluster | VMware cluster name | string | | yes |

## Outputs

| Name | Description |
|------|-------------|
| pool_id | Pool ID |
