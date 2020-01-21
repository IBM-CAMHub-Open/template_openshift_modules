<!---
Copyright IBM Corp. 2019, 2019
--->

# Install and Configure HAProxy LB Server Module

This modules installs HAProxy and configures as LB server for the following OCP URLs:
api-int, api and apps

## OS requirements

Supported On RHEL 7.x Linux

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| dependsOn | Boolean for dependency | string | `true` | no |
| vm_ipv4_address | IPv4 address for vNIC configuration | list | - | yes |
| vm_os_password | Password for the Operating System User to access virtual machine | string | - | yes |
| vm_os_private_key |  | string | `` | no |
| vm_os_user | User for the Operating System User to access virtual machine | string | - | yes |
| vm_ipv4_controlplane_addresses | Comma separated IPv4 address for control or boot nodes. Required if configure_api_url or remove_api_url is true. |  string | - |  no
| vm_ipv4_worker_addresses | Comma separated IPv4 address for worker nodes. Required if configure_app_url or remove_app_url is true. |  string | - |  no
| install | Boolean for installing HAProxy. If set to true, then configure_api_url, configure_app_url, remove_api_url and remove_app_url must be false or empty. | string | false | no
| configure_api_url | Boolean to add LB nodes to api and api-int. If set to true, then install, configure_app_url, remove_api_url and remove_app_url must be false or empty. | string | false | no
| configure_app_url | Boolean to add LB nodes to apps. If set to true, then install, configure_api_url, remove_api_url and remove_app_url must be false or empty. | string | false | no
| remove_api_url | Boolean to remove LB nodes from api. If set to true, then install, configure_api_url, configure_app_url and remove_app_url must be false or empty. | string | false | no
| remove_app_url | Boolean to remove LB nodes from app. If set to true, then install, configure_api_url, configure_app_url and remove_api_url must be false or empty. | string | false | no
| is_boot | Boolean to indicate boot node. Must be set to true if LB rule is for boot node.  | string | false | no

## Outputs

| Name | Description |
|------|-------------|
| dependsOn | Output Parameter set when the module execution is completed |
