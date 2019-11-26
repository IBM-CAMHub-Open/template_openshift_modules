resource "null_resource" "apache_web_server_dependsOn" {
  provisioner "local-exec" {
    # Hack to force dependencies to work correctly. Must use the dependsOn var somewhere in the code for dependencies to work. Contain value which comes from previous module.
	  command = "echo The dependsOn output for apache web server module is ${var.dependsOn}"
  }
}

resource "null_resource" "create_apache_web_server" {
  depends_on = ["null_resource.apache_web_server_dependsOn"]
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
    source = "${path.module}/scripts/setup_apache_web.sh"
    destination = "/tmp/setup_apache_web.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "set -e",
      "chmod +x /tmp/setup_apache_web.sh",
      "bash -c '/tmp/setup_apache_web.sh'"
    ]
  }
}

resource "null_resource" "apache_web_server_created" {
  depends_on = ["null_resource.create_apache_web_server","null_resource.apache_web_server_dependsOn"]
  provisioner "local-exec" {
    command = "echo 'Apache Web server created'" 
  }
}
