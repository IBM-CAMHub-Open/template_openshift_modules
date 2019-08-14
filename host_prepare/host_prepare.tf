resource "null_resource" "master_dependsOn" {
  provisioner "local-exec" {
# Hack to force dependencies to work correctly. Must use the dependsOn var somewhere in the code for dependencies to work. Contain value which comes from previous module.
	  command = "echo The dependsOn output for hostfile module is ${var.dependsOn}"
  }
}
resource "null_resource" "prepare_node" {
  depends_on = ["null_resource.master_dependsOn"]

  count = "${length(var.vm_ipv4_address_list)}"
  connection {
    type = "ssh"
    user = "${var.vm_os_user}"
    password =  "${var.vm_os_password}"
    private_key = "${var.private_key}"
    timeout = "30m"
    host = "${var.vm_ipv4_address_list[count.index]}"
    bastion_host        = "${var.bastion_host}"
    bastion_user        = "${var.bastion_user}"
    bastion_private_key = "${ length(var.bastion_private_key) > 0 ? base64decode(var.bastion_private_key) : var.bastion_private_key}"
    bastion_port        = "${var.bastion_port}"
    bastion_host_key    = "${var.bastion_host_key}"
    bastion_password    = "${var.bastion_password}"      
  }
  provisioner "file" {
    source = "${path.module}/scripts/host_prepare.sh"
    destination = "/tmp/host_prepare.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "set -e",
      "chmod 755 /tmp/host_prepare.sh",
      "bash -c '/tmp/host_prepare.sh ${var.rh_user} ${var.rh_password} ${var.vm_hostname_list} ${var.installer_hostname} ${var.vm_domain_name} ${var.vm_os_password} ${var.compute_hostname}'"
      #"(sleep 5 && reboot)&"
    ]
  }

  provisioner "remote-exec" {
    when                  = "destroy"
    inline                = [
      "subscription-manager unregister"
    ]
    on_failure = "continue"
  }
}

resource "null_resource" "host_populate" {
  depends_on = ["null_resource.prepare_node"]
  provisioner "local-exec" {
    command = "echo 'Hosts are ready.'" #${var.vm_ipv4_address_list}.'"
  }
}
