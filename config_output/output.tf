output "cluster_config"{
  depends_on = ["camc_scriptpackage.get_cluster_config"]
  value = "${camc_scriptpackage.get_cluster_config.result["config"]}"
} 

output "cluster_certificate_authority"{
  depends_on = ["camc_scriptpackage.get_cluster_config"]
  value = "${camc_scriptpackage.get_cluster_config.result["config_ca_cert_data"]}"
} 

output "cluster_name"{
  depends_on = ["camc_scriptpackage.get_cluster_config"]
  value = "${camc_scriptpackage.get_cluster_config.result["cluster_name"]}"
} 

output "dependsOn" { 
	value = "${null_resource.output_create_finished.id}" 
	description="Output Parameter when Module Complete"
}


