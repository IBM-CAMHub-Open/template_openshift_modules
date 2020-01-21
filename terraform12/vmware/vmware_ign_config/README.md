<!---
Copyright IBM Corp. 2019, 2019
--->

# Config OCP Infra node

This module installs OC Install Server, Client and OC CLI on Infra node prior to starting up the OCP installation.
This creates necessary ignition and manifest files of OCP install. Also configures firewall rules and NAT between the
OCP cluster private network and data center public network. 

## OS requirements

Supported On RHEL 7.x Linux


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| dependsOn | Boolean for dependency | string | `true` | no |
| vm_ipv4_address | IPv4 address for vNIC configuration | string | - | yes |
| vm_ipv4_private_address | Private IPv4 address for vNIC configuration | string | - | yes | 
| vm_os_password | Password for the Operating System User to access virtual machine | string | - | yes |
| vm_os_private_key_base64 | Base64 encoded key | string | `` | no |
| vm_os_user | User for the Operating System User to access virtual machine | string | - | yes |
| ocversion | OCP Version | string | 4.2.0 | no |
| clustername | OCP cluster name | string | | no |
| domain | OCP Base domain name | string |  | yes |
| controlnodes | Number of OCP Control nodes | string | 3 | no |
| computenodes | Number of OCP Control nodes | string | 2 | no |
| vcenter | vCenter name | string |  | yes|
| vcenteruser | vCenter user | string |  | yes|
| vcenterpassword | vCenter password | string |  | yes |
| vcenterdatacenter | vCenter data center| string |  | yes |
| vmwaredatastore | VMware Datastore | string |  | yes |
| pullsecret | vBase64 encoded OCP image pull secret | string |  | yes |

<br />


## Outputs

| Name | Description |
|------|-------------|
| dependsOn | Output Parameter set when the module execution is completed |
| bootstrap_ign | Base64 encoded original bootstrap ignition file |
| bootstrap_sec_ign | Base64 encoded Bootstrap ignition file that points to the original file in the HTTP server installed on Infra node. |
| master_ign | List of Base64 encoded master ignition file that points to the original file in the HTTP server installed on Infra node. Each file in the list sets the unique hostname to the compute nodes. |
| worker_ign | List of Base64 encoded worker ignition file that points to the original file in the HTTP server installed on Infra node. Each file in the list sets the unique hostname to the compute nodes. |
| cluster_prvt_key | Private key to login to the cluster nodes from the Inra node. |
| private_interface | Private interface of infra node. |
| public_interface | Public interface of infra node. |
