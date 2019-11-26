resource "null_resource" "wait_for_api_url_dependsOn" {
  provisioner "local-exec" {
    # Hack to force dependencies to work correctly. Must use the dependsOn var somewhere in the code for dependencies to work. Contain value which comes from previous module.
	  command = "echo The dependsOn output is ${var.dependsOn}"
  }
}

resource "null_resource" "wait_for_api_url" {
  depends_on = ["null_resource.wait_for_api_url_dependsOn"]
  connection {
    type = "ssh"
    user = "${var.vm_os_user}"
    password =  "${var.vm_os_password}"
    private_key = "${var.vm_os_private_key}"
    host = "${var.vm_ipv4_address}"
    bastion_host        = "${var.bastion_host}"
    bastion_user        = "${var.bastion_user}"
    bastion_private_key = "${ length(var.bastion_private_key) > 0 ? base64decode(var.bastion_private_key) : var.bastion_private_key}"
    bastion_port        = "${var.bastion_port}"
    bastion_host_key    = "${var.bastion_host_key}"
    bastion_password    = "${var.bastion_password}"     
  }

  provisioner "file" {
    source = "${path.module}/scripts/wait_for_api_url.sh"
    destination = "/tmp/wait_for_api_url.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "set -e",
      "chmod +x /tmp/wait_for_api_url.sh",
      "bash -c '/tmp/wait_for_api_url.sh ${var.ocp_cluster_name} ${var.ocp_domain} ${var.api_type}'"
    ]
  }
}

resource "null_resource" "wait_for_api_url_complete" {
  depends_on = ["null_resource.wait_for_api_url","null_resource.wait_for_api_url_dependsOn"]
  provisioner "local-exec" {
    command = "echo 'Bootstrap monitor created'" 
  }
}