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
variable "dependsOn" {
  default = "true"
  description = "Boolean for dependency"
}
variable "vm_os_private_key" {
  default = ""
  description = "OS Private Key"
}
variable "ocp_domain" {
  description = "OCP Domain Name"
  type = "string"
}
variable "ocp_cluster_name" {
  description = "OCP cluster name"
  type = "string"
}
variable "number_nodes" {
  description = "Number of nodes"
  type = "string"
}
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