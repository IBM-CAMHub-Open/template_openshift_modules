<!---
Copyright IBM Corp. 2019, 2019
--->

# Config OCP Ignition Files

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
| domain | OCP Base domain name | string |  | yes |
| controlnodes | Number of OCP Control nodes | string | 3 | no |
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
| dependsOn | Output Parameter when Module Complete |
| dependsOn | Output Parameter when Module Complete |
| dependsOn | Output Parameter when Module Complete |
| dependsOn | Output Parameter when Module Complete |
