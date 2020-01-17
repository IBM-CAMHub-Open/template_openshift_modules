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

variable "compute_nodes" {
  default = "2"
  description = "Total number of compute nodes"
}

variable "control_nodes" {
  default = "3"
  description = "Total number of control nodes"
}

variable "get_type" {
  default = "all"
  description = "Which node IP to get. Valid values are all,compute,control"
}