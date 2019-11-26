output "ip" {
  value = "${vsphere_virtual_machine.vm.*.default_ip_address}"
}

output "name" {
  value = "${vsphere_virtual_machine.vm.*.name}"
}

output "dependsOn" { 
	value = "${null_resource.machine_created.id}"
	description="Output Parameter when Module Complete"
}