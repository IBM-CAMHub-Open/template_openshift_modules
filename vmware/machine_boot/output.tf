output "ip" {
  value = "${vsphere_virtual_machine.vm.*.default_ip_address}"
}

output "allip" {
  value = "${vsphere_virtual_machine.vm.*.guest_ip_addresses}"
}

output "name" {
  value = "${vsphere_virtual_machine.vm.*.name}"
}

output "dependsOn" { 
	value = "${null_resource.machine_created.id}"
	description="Output Parameter set when the module execution is completed"
}