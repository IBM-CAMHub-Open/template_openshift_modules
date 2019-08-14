resource "null_resource" "master_dependsOn" {
  provisioner "local-exec" {
# Hack to force dependencies to work correctly. Must use the dependsOn var somewhere in the code for dependencies to work. Contain value which comes from previous module.
	  command = "echo The dependsOn output for hostfile module is ${var.dependsOn}"
  }
}
resource "null_resource" "scale_node" {
  depends_on = ["null_resource.master_dependsOn"]

  triggers {
    workers = "${join(",", var.compute_node_ip)}"
  }

  connection {
    type = "ssh"
    user = "${var.vm_os_user}"
    password =  "${var.vm_os_password}"
    private_key = "${var.private_key}"
    timeout = "30m"
    host = "${var.master_node_ip}"
    bastion_host        = "${var.bastion_host}"
    bastion_user        = "${var.bastion_user}"
    bastion_private_key = "${length(var.bastion_private_key) > 0 ? base64decode(var.bastion_private_key) : var.bastion_private_key}"
    bastion_port        = "${var.bastion_port}"
    bastion_host_key    = "${var.bastion_host_key}"
    bastion_password    = "${var.bastion_password}"      
  }

  provisioner "remote-exec" {
    inline = [
      "echo -n ${join(",", var.compute_node_hostname)} > /tmp/new_compute.txt"    
    ]
  }

  provisioner "file" {
    source = "${path.module}/scripts/scale_node.sh"
    destination = "/tmp/scale_node.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "set -e",
      "chmod 755 /tmp/scale_node.sh",
      "bash -c '/tmp/scale_node.sh ${var.vm_domain_name} ${var.vm_os_password}'"
    ]
  }
}

resource "null_resource" "finish_installing" {
  depends_on = ["null_resource.scale_node"]
  provisioner "local-exec" {
    command = "echo 'Scale Node Openshift 3.11 finished successfully'"
  }
}
