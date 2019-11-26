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
variable "vm_ipv4_private_address" {
  description = "IPv4 address for private vNIC configuration"
  type = "string"
}
variable "dependsOn" {
  default = "true"
  description = "Boolean for dependency"
}
variable "vm_os_private_key_base64" {
  default = ""
  description = "Base64 encoded key"
}
variable "ocversion"{
  type = "string"
  default = "4.2.0"
  description = "OCP Version"
}
variable "domain" {
  type = "string"
  description = "OCP Base domain name"
}
variable "clustername" {
  type = "string"
  description = "OCP Cluster name"
}
variable "controlnodes" {
  type = "string"
  default = "3"
  description = "Number of OCP Control nodes."
}
variable "computenodes" {
  type = "string"
  default = "2"
  description = "Number of OCP Compute nodes."
}
variable "vcenter" {
  type = "string"
  description = "vCenter name"
}
variable "vcenteruser" {
  type = "string"
  description = "vCenter user"
}
variable "vcenterpassword" {
  type = "string"
  description = "vCenter password"
}
variable "vcenterdatacenter" {
  type = "string"
  description = "vCenter data center"
}
variable "vmwaredatastore" {
  type = "string"
  description = "VMware Datastore"
}
variable "pullsecret" {
  type = "string"
  description = "Base64 encoded OCP image pull secret."
}
