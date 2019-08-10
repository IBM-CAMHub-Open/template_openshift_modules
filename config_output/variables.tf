variable "dependsOn" {
  default = "true"
  description = "Boolean for dependency"
}

variable "master_node_ip" {
  type = "string"
  description = "OpenShift Master Node IP"
}

variable "vm_os_user" {
  type = "string"
}

variable "vm_os_password" {
  type = "string"
}

variable "vm_os_private_key" {
  type = "string"
}

variable "openshift_cluster_name" {
  type = "string"
  default = ""
  description = "OpenShift Cluster name to be used in generated kube config"
}

variable "openshift_server" {
  type = "string"
  description = "OpenShift server host or IP"
}

variable "openshift_port" {
  type = "string"
  description = "OpenShift API port"
}

variable "openshift_user" {
  type = "string"
  description = "OpenShift Admin User name"
}