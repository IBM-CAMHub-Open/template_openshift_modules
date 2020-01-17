output "dependsOn" { 
	value = "${null_resource.get_permanent_ip_complete.id}"
	description="Output Parameter set when the module execution is completed"
}

output "control_ip" {
    value = ["${camc_scriptpackage.get_control_ip.result["control"]}"]
    description="OCP control IPv4"
}

output "compute_ip" {
    value = ["${camc_scriptpackage.get_compute_ip.result["compute"]}"]
    description="OCP compute IPv4"
}
