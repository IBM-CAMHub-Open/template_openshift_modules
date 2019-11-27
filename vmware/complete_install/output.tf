output "dependsOn" { 
	value = "${null_resource.installed.id}"
	description="Output Parameter set when the module execution is completed"
}

output "console"{
  depends_on = ["camc_scriptpackage.get_creds"]
  value = "${camc_scriptpackage.get_creds.result["Console"]}"
  description="OCP console URL"
} 

output "password"{
  depends_on = ["camc_scriptpackage.get_creds"]
  value = "${camc_scriptpackage.get_creds.result["Password"]}"
  description="kubeadmin password"
} 