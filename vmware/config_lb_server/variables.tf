variable "vm_os_password" {
  type = "string"
  description = "Password for the Operating System User to access virtual machine"
}
variable "vm_os_user" {
  type = "string"
  description = "User for the Operating System User to access virtual machine"
}
variable "vm_ipv4_address" {
  description = "IPv4 address for vNIC configuration"
  type = "string"
}
###
#
###
variable "vm_ipv4_controlplane_addresses" {
  description = "Comma separated IPv4 address for control or boot nodes. Required if configure_api_url or remove_api_url is true."
  type = "string"
  default = ""
}
variable "vm_ipv4_worker_addresses" {
  description = "Comma separated IPv4 address for worker nodes. Required if configure_app_url or remove_app_url is true."
  type = "string"
  default = ""
}
variable "dependsOn" {
  default = "true"
  description = "Boolean for dependency"
}
variable "vm_os_private_key" {
  default = ""
}
###
#Following five must be used as mutually exclusive.
#Only one operation must be used for a module call.
###
variable "install" {
  description = "Boolean for installing HAProxy. If set to true, then configure_api_url, configure_app_url, remove_api_url and remove_app_url must be false or empty."
  type = "string"
  default = "false"
}
variable "configure_api_url" {
  description = "Boolean to add LB nodes to api and api-int. If set to true, then install, configure_app_url, remove_api_url and remove_app_url must be false or empty."
  type = "string"
  default = "false"
}
variable "configure_app_url" {
  description = "Boolean to add LB nodes to apps. If set to true, then install, configure_api_url, remove_api_url and remove_app_url must be false or empty."
  type = "string"
  default = "false"
}
variable "remove_api_url" {
  description = "Boolean to remove LB nodes from api. If set to true, then install, configure_api_url, configure_app_url and remove_app_url must be false or empty."
  type = "string"
  default = "false"
}
variable "remove_app_url" {
  description = "Boolean to remove LB nodes from app. If set to true, then install, configure_api_url, configure_app_url and remove_api_url must be false or empty."
  type = "string"
  default = "false"
}
####
#Set true only for configure_api_url operation
####
variable "is_boot" {
  description = "Boolean to indicate boot node"
  type = "string"
  default = "false"
}

