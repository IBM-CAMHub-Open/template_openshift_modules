variable "vm_os_password"       { type = "string"  description = "Operating System Password for the Operating System User to access virtual machine"}
variable "vm_os_user"           { type = "string"  description = "Operating System user for the Operating System User to access virtual machine"}
variable "installer_vm_ipv4_address" { type="string"      description = "Master IPv4 Address's in List format"}
variable "private_key"          { type = "string"  description = "Private SSH key Details to the Virtual machine"}
# variable "node_vm_ipv4_address"       { type = "list"}
variable "node_vm_hostname"   { type = "list"}
variable "vm_domain_name"          { type = "string"}
variable "random"               { type = "string"  description = "Random String Generated"}
variable "dependsOn"            { default = "true" description = "Boolean for dependency"}