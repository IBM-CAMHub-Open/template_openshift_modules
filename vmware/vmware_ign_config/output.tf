output "dependsOn" { 
	value = "${null_resource.ign_config_generated.id}" 
	description="Output Parameter set when the module execution is completed"
}

output "bootstrap_ign"{
  depends_on = ["camc_scriptpackage.get_bootstrap_ign"]
  value = ["${camc_scriptpackage.get_bootstrap_ign.result["stdout"]}"]
  description="Base64 encoded bootstrap ign"
} 

output "bootstrap_sec_ign"{
  depends_on = ["camc_scriptpackage.get_bootstrap_sec_ign"]
  #value = ["${camc_scriptpackage.get_bootstrap_sec_ign.result["stdout"]}"]
  value = "${camc_scriptpackage.get_bootstrap_sec_ign.result["stdout"]}"
  description="Base64 encoded bootstrap url ign"
} 

output "master_ign"{
  depends_on = ["camc_scriptpackage.get_master_ign"]
  #value = ["${split("," , camc_scriptpackage.get_master_ign.result["stdout"])}"]
  value = "${camc_scriptpackage.get_master_ign.result["stdout"]}"
  description="Base64 encoded master ign"
} 

output "worker_ign"{
  depends_on = ["camc_scriptpackage.get_worker_ign"]
  #value = ["${split(",",camc_scriptpackage.get_worker_ign.result["stdout"])}"]
  value = "${camc_scriptpackage.get_worker_ign.result["stdout"]}"
  description="Base64 encoded worker ign"
} 

output "cluster_prvt_key"{
  depends_on = ["camc_scriptpackage.get_cluster_key"]
  value = "${camc_scriptpackage.get_cluster_key.result["stdout"]}"
  description="Base64 encoded cluster prvt key"
} 

output "private_interface"{
  depends_on = ["camc_scriptpackage.get_interfaces"]
  value = "${camc_scriptpackage.get_interfaces.result["privateintf"]}"
  description="Private interface"
} 

output "public_interface"{
  depends_on = ["camc_scriptpackage.get_interfaces"]
  value = "${camc_scriptpackage.get_interfaces.result["publicintf"]}"
  description="Public interface"
} 
