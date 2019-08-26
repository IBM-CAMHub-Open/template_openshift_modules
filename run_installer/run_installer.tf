resource "null_resource" "master_dependsOn" {
  provisioner "local-exec" {
# Hack to force dependencies to work correctly. Must use the dependsOn var somewhere in the code for dependencies to work. Contain value which comes from previous module.
	  command = "echo The dependsOn output for hostfile module is ${var.dependsOn}"
  }
}
resource "null_resource" "run_installer" {
  depends_on = ["null_resource.master_dependsOn"]

  connection {
    type = "ssh"
    user = "${var.vm_os_user}"
    password =  "${var.vm_os_password}"
    private_key = "${var.private_key}"
    host = "${element(var.master_node_ip, 0)}"
    bastion_host        = "${var.bastion_host}"
    bastion_user        = "${var.bastion_user}"
    bastion_private_key = "${length(var.bastion_private_key) > 0 ? base64decode(var.bastion_private_key) : var.bastion_private_key}"
    bastion_port        = "${var.bastion_port}"
    bastion_host_key    = "${var.bastion_host_key}"
    bastion_password    = "${var.bastion_password}"      
  }

  provisioner "file" {
    source = "${path.module}/scripts/run_installer.sh"
    destination = "/tmp/run_installer.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "set -e",
      "chmod 755 /tmp/run_installer.sh",
      "bash -c '/tmp/run_installer.sh ${var.openshift_user} ${var.openshift_password} ${join(",", var.master_node_ip)}'"
    ]
  }
}

resource "null_resource" "finish_installing" {
  depends_on = ["null_resource.run_installer"]
  provisioner "local-exec" {
    command = "echo 'Installing OpenShift 3.11 finished successfully'"
  }
}
