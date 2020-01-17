resource "null_resource" "machine_dependsOn" {
  provisioner "local-exec" {
    # Hack to force dependencies to work correctly. Must use the dependsOn var somewhere in the code for dependencies to work. Contain value which comes from previous module.
	  command = "echo The dependsOn output is ${var.dependsOn}"
  }
}

data "vsphere_datastore" "datastore" {
  name          = "${var.datastore}"
  datacenter_id = "${var.datacenter_id}"
}

data "vsphere_network" "network" {
  name          = "${var.network}"
  datacenter_id = "${var.datacenter_id}"
}

data "vsphere_virtual_machine" "template" {
  name          = "${var.template}"
  datacenter_id = "${var.datacenter_id}"
}

resource "vsphere_virtual_machine" "vm" {
  depends_on = ["null_resource.machine_dependsOn"]
  count = "${var.instance_count}"
  wait_for_guest_net_timeout = "${var.wait_for_guest_net_timeout}"
  name             = "${var.name}-${count.index}"
  resource_pool_id = "${var.resource_pool_id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"
  num_cpus         = "${var.cpu}"
  memory           = "${var.memory}"
  guest_id         = "${data.vsphere_virtual_machine.template.guest_id}"
  folder           = "${var.folder}"
  enable_disk_uuid = "true"

  network_interface {
    network_id = "${data.vsphere_network.network.id}"
    #use_static_mac =  "${var.use_static_mac}"
    #mac_address = "${var.mac_address[count.index]}"
  }

  disk {
    label            = "disk0"
    size             = "${var.disk_size}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"
  }

  vapp {
    properties {
      #"guestinfo.ignition.config.data" = "${var.ignition[count.index]}"
      "guestinfo.ignition.config.data" = "${element(split("," ,var.ignition),count.index)}"
      "guestinfo.ignition.config.data.encoding" = "base64"
    }
  }
  
  provisioner "file" {
	  connection {
	    type = "ssh"
	    user = "${var.vm_os_user}"
	    password =  "${var.vm_os_password}"
	    private_key = "${base64decode(var.vm_os_private_key_base64)}"
	    host = "${var.vm_ipv4_address}"
	    bastion_host        = "${var.bastion_host}"
	    bastion_user        = "${var.bastion_user}"
	    bastion_private_key = "${ length(var.bastion_private_key) > 0 ? base64decode(var.bastion_private_key) : var.bastion_private_key}"
	    bastion_port        = "${var.bastion_port}"
	    bastion_host_key    = "${var.bastion_host_key}"
	    bastion_password    = "${var.bastion_password}"        
	  }	  
      source = "${path.module}/scripts/delete_infra.sh"
      destination = "/tmp/delete_infra.sh"
      when    = "destroy"
  }   
  
  provisioner "remote-exec" {
	  connection {
	    type = "ssh"
	    user = "${var.vm_os_user}"
	    password =  "${var.vm_os_password}"
	    private_key = "${base64decode(var.vm_os_private_key_base64)}"
	    host = "${var.vm_ipv4_address}"
	    bastion_host        = "${var.bastion_host}"
	    bastion_user        = "${var.bastion_user}"
	    bastion_private_key = "${ length(var.bastion_private_key) > 0 ? base64decode(var.bastion_private_key) : var.bastion_private_key}"
	    bastion_port        = "${var.bastion_port}"
	    bastion_host_key    = "${var.bastion_host_key}"
	    bastion_password    = "${var.bastion_password}"        
	  }	   
	  when    = "destroy"
    inline = [
      "set -e",
      "chmod +x /tmp/delete_infra.sh",
      "bash -c '/tmp/delete_infra.sh ${var.instance_type} ${var.instance_count} ${var.clustername} ${var.domain} ${count.index}'"
    ]
  }   
}

resource "null_resource" "machine_created" {
  depends_on = ["null_resource.machine_dependsOn","vsphere_virtual_machine.vm"]
  provisioner "local-exec" {
    command = "echo 'OCP machine created'" 
  }
}

