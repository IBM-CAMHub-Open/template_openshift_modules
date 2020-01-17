resource "null_resource" "master_dependsOn" {
  provisioner "local-exec" {
      # Force dependencies to work correctly. Must use the dependsOn var somewhere in the code for dependencies to work. Contain value which comes from previous module.
	  command = "echo The dependsOn output for hostfile module is ${var.dependsOn}"
  }
}

resource "null_resource" "setup_dns_server" {
  depends_on = ["null_resource.master_dependsOn"]
  
  count = "${var.action == "setup" ? 1 : 0}"

  connection {
    type                = "ssh"
    user                = "${var.vm_os_user}"
    password            = "${var.vm_os_password}"
    private_key         = "${var.private_key}"
    host                = "${var.dns_server_ip}"
    bastion_host        = "${var.bastion_host}"
    bastion_user        = "${var.bastion_user}"
    bastion_private_key = "${length(var.bastion_private_key) > 0 ? base64decode(var.bastion_private_key) : var.bastion_private_key}"
    bastion_port        = "${var.bastion_port}"
    bastion_host_key    = "${var.bastion_host_key}"
    bastion_password    = "${var.bastion_password}"      
  }

  provisioner "file" {
    source = "${path.module}/scripts/config_dns.sh"
    destination = "/tmp/config_dns.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "set -e",
      "chmod 755 /tmp/config_dns.sh",
      "bash -c '/tmp/config_dns.sh -ac ${var.action} -ip ${var.dns_server_ip} -ci ${var.cluster_ip} -cn ${var.cluster_name} -dn ${var.domain_name}'"
    ]
  }
}


resource "null_resource" "setup_dhcp" {
  depends_on = ["null_resource.master_dependsOn", "null_resource.setup_dns_server"]
  
  count = "${var.action == "dhcp" ? 1 : 0}"

  connection {
    type                = "ssh"
    user                = "${var.vm_os_user}"
    password            = "${var.vm_os_password}"
    private_key         = "${var.private_key}"
    host                = "${var.dns_server_ip}"
    bastion_host        = "${var.bastion_host}"
    bastion_user        = "${var.bastion_user}"
    bastion_private_key = "${length(var.bastion_private_key) > 0 ? base64decode(var.bastion_private_key) : var.bastion_private_key}"
    bastion_port        = "${var.bastion_port}"
    bastion_host_key    = "${var.bastion_host_key}"
    bastion_password    = "${var.bastion_password}"      
  }

  provisioner "file" {
    source = "${path.module}/scripts/config_dns.sh"
    destination = "/tmp/config_dns.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "set -e",
      "chmod 755 /tmp/config_dns.sh",
      "bash -c '/tmp/config_dns.sh -ac ${var.action} -di ${var.dhcp_interface} -dr ${var.dhcp_router_ip} -ds ${var.dhcp_ip_range_start} -de ${var.dhcp_ip_range_end} -dm ${var.dhcp_netmask} -dl ${var.dhcp_lease_time}'"
    ]
  }
}


resource "null_resource" "add_master_node_dns_record" {
  depends_on = ["null_resource.master_dependsOn", "null_resource.setup_dns_server", "null_resource.setup_dhcp"]
  count = "${var.action == "addMaster" ? 1 : 0}"
  connection {
    type                = "ssh"
    user                = "${var.vm_os_user}"
    password            =  "${var.vm_os_password}"
    private_key         = "${var.private_key}"
    host                = "${var.dns_server_ip}"
    bastion_host        = "${var.bastion_host}"
    bastion_user        = "${var.bastion_user}"
    bastion_private_key = "${length(var.bastion_private_key) > 0 ? base64decode(var.bastion_private_key) : var.bastion_private_key}"
    bastion_port        = "${var.bastion_port}"
    bastion_host_key    = "${var.bastion_host_key}"
    bastion_password    = "${var.bastion_password}"      
  }

  provisioner "file" {
    source = "${path.module}/scripts/config_dns.sh"
    destination = "/tmp/config_dns.sh"
  }
  
  #triggers {
  #	control_node_changed = "${var.node_ips}"
  #}

  provisioner "remote-exec" {
    inline = [
      "set -e",
      "chmod 755 /tmp/config_dns.sh",
      "bash -c '/tmp/config_dns.sh -ac ${var.action} -cn ${var.cluster_name} -dn ${var.domain_name} -ni ${var.node_ips} -nn ${var.node_names}'"
    ]
  }
}


resource "null_resource" "add_worker_node_dns_record" {
  depends_on = ["null_resource.master_dependsOn", "null_resource.setup_dns_server", "null_resource.setup_dhcp", "null_resource.add_master_node_dns_record"]
  count = "${var.action == "addWorker" ? 1 : 0}"
  connection {
    type                = "ssh"
    user                = "${var.vm_os_user}"
    password            =  "${var.vm_os_password}"
    private_key         = "${var.private_key}"
    host                = "${var.dns_server_ip}"
    bastion_host        = "${var.bastion_host}"
    bastion_user        = "${var.bastion_user}"
    bastion_private_key = "${length(var.bastion_private_key) > 0 ? base64decode(var.bastion_private_key) : var.bastion_private_key}"
    bastion_port        = "${var.bastion_port}"
    bastion_host_key    = "${var.bastion_host_key}"
    bastion_password    = "${var.bastion_password}"      
  }

  provisioner "file" {
    source = "${path.module}/scripts/config_dns.sh"
    destination = "/tmp/config_dns.sh"
  }
  
  triggers {
  	compute_node_changed = "${var.node_ips}"
  }

  provisioner "remote-exec" {
    inline = [
      "set -e",
      "chmod 755 /tmp/config_dns.sh",
      "bash -c '/tmp/config_dns.sh -ac ${var.action} -cn ${var.cluster_name} -dn ${var.domain_name} -ni ${var.node_ips} -nn ${var.node_names}'"
    ]
  }
}


resource "null_resource" "finish_config_dns" {
  depends_on = ["null_resource.setup_dns_server", "null_resource.setup_dhcp", "null_resource.add_master_node_dns_record", "null_resource.add_worker_node_dns_record"]
  provisioner "local-exec" {
    command = "echo 'Configuring DNS server finished successfully.'"
  }
}
