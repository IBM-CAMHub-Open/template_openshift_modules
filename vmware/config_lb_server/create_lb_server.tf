resource "null_resource" "create_lb_server_dependsOn" {
  provisioner "local-exec" {
    # Hack to force dependencies to work correctly. Must use the dependsOn var somewhere in the code for dependencies to work. Contain value which comes from previous module.
	  command = "echo The dependsOn output for lb server module is ${var.dependsOn}"
  }
}

resource "null_resource" "create_lb_server" {
  depends_on = ["null_resource.create_lb_server_dependsOn"]
  count = "${var.install == "true" ? 1 : 0}"
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
    source = "${path.module}/scripts/setup_lb.sh"
    destination = "/tmp/setup_lb.sh"
  }
  
  provisioner "remote-exec" {
    inline = [
      "set -e",
      "chmod +x /tmp/setup_lb.sh",
      "bash -c '/tmp/setup_lb.sh install'"
    ]
  }
}

resource "null_resource" "configapi" {
  depends_on = ["null_resource.create_lb_server_dependsOn"]
  count = "${var.configure_api_url == "true" ? 1 : 0}"
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
    source = "${path.module}/scripts/setup_lb.sh"
    destination = "/tmp/setup_lb.sh"
  }
  
  provisioner "file" {
    source = "${path.module}/scripts/lb_api.tmpl"
    destination = "/tmp/lb_api.tmpl"
  }
  
  #triggers{
  #	vm_ipv4_controlplane_addresses_changed="${var.vm_ipv4_controlplane_addresses}"
  #}
  
  provisioner "remote-exec" {
    inline = [
      "set -e",
      "chmod +x /tmp/setup_lb.sh",
      "bash -c '/tmp/setup_lb.sh configapi ${var.vm_ipv4_controlplane_addresses} ${var.is_boot}'"
    ]
  }
}

resource "null_resource" "removeapi" {
  depends_on = ["null_resource.create_lb_server_dependsOn"]
  count = "${var.remove_api_url == "true" ? 1 : 0}"
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
    source = "${path.module}/scripts/setup_lb.sh"
    destination = "/tmp/setup_lb.sh"
  }
  
  provisioner "remote-exec" {
    inline = [
      "set -e",
      "chmod +x /tmp/setup_lb.sh",
      "bash -c '/tmp/setup_lb.sh removeapi ${var.vm_ipv4_controlplane_addresses}'"
    ]
  }
}

resource "null_resource" "configapp" {
  depends_on = ["null_resource.create_lb_server_dependsOn"]
  count = "${var.configure_app_url == "true" ? 1 : 0}"
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
    source = "${path.module}/scripts/setup_lb.sh"
    destination = "/tmp/setup_lb.sh"
  }
  
  provisioner "file" {
    source = "${path.module}/scripts/lb_app.tmpl"
    destination = "/tmp/lb_app.tmpl"
  }
  
  triggers{
  	vm_ipv4_worker_addresses_changed="${var.vm_ipv4_worker_addresses}"
  }  
  
  provisioner "remote-exec" {
    inline = [
      "set -e",
      "chmod +x /tmp/setup_lb.sh",
      "bash -c '/tmp/setup_lb.sh configapp ${var.vm_ipv4_worker_addresses}'"
    ]
  }
}

resource "null_resource" "removeapp" {
  depends_on = ["null_resource.create_lb_server_dependsOn"]
  count = "${var.remove_app_url == "true" ? 1 : 0}"
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
    source = "${path.module}/scripts/setup_lb.sh"
    destination = "/tmp/setup_lb.sh"
  }
  
  provisioner "remote-exec" {
    inline = [
      "set -e",
      "chmod +x /tmp/setup_lb.sh",
      "bash -c '/tmp/setup_lb.sh removeapp ${var.vm_ipv4_worker_addresses}'"
    ]
  }
}

resource "null_resource" "lb_server_create" {
  depends_on = ["null_resource.create_lb_server","null_resource.create_lb_server_dependsOn", "null_resource.configapi", "null_resource.configapp", "null_resource.removeapi", "null_resource.removeapp"]
  provisioner "local-exec" {
    command = "echo 'HAPRoxy LB server created'" 
  }
}
