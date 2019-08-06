variable "vm_os_password"       { type = "string"  description = "Operating System Password for the Operating System User to access virtual machine"}
variable "vm_os_user"           { type = "string"  description = "Operating System user for the Operating System User to access virtual machine"}
variable "private_key"          { type = "string"  description = "Private SSH key Details to the Virtual machine"}
variable "master_vm_ipv4_address"       { type = "string"}
variable "master_vm_hostname"           { type = "string"}
variable "etcd_vm_hostname"             { type = "string"}
variable "compute_vm_hostname"           { type = "string"}

variable "lb_vm_hostname"             { type = "string"}
variable "enable_lb"             { type = "string"}
variable "domain_name"           { type = "string"}
variable "infra_vm_hostname"             { type = "string"}
variable "infra_vm_ipv4_address"         { type = "string"}
variable "rh_user"              { type = "string" }
variable "rh_password"          { type = "string" }
variable "compute_enable_glusterFS"          { type = "string"}
variable "random"               { type = "string"  description = "Random String Generated"}
variable "dependsOn"            { default = "true" description = "Boolean for dependency"}