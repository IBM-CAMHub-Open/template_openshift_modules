variable "name" {
  type = "string"
}

variable "instance_count" {
  type = "string"
}

variable "ignition" {
  type    = "list"
  default = []
}

variable "resource_pool_id" {
  type = "string"
}

variable "folder" {
  type = "string"
}

variable "datastore" {
  type = "string"
}

variable "network" {
  type = "string"
}

variable "datacenter_id" {
  type = "string"
}

variable "template" {
  type = "string"
}

variable "memory" {
  type = "string"
}

variable "cpu" {
  type = "string"
  default = "4"
}

variable "disk_size" {
  type = "string"
  default = "120"
}

#variable "use_static_mac" {
#  type = "string"
#}

#variable "mac_address" {
#  type = "list"
#}

variable "dependsOn" {
  default = "true"
  description = "Boolean for dependency"
}

variable "wait_for_guest_net_timeout" {
  default = "5"
  description = "Wait for IP to show up"
}
