<!---
Copyright IBM Corp. 2019, 2019
--->

# Create VMware folder for OCP cluster nodes.

Create a folder. Name of the folder must match the OCP cluster name.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| path | Folder name | string |  | yes |
| datacenter_id | VMware DC ID | string | | yes |

## Outputs

| Name | Description |
|------|-------------|
| path | Folder path |
