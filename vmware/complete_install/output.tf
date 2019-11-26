output "dependsOn" { 
	value = "${null_resource.installed.id}"
	description="Output Parameter when Module Complete"
}

output "console"{
  depends_on = ["camc_scriptpackage.get_creds"]
  value = "${camc_scriptpackage.get_creds.result["Console"]}"
  description="OCP console URL"
} 

output "password"{
  depends_on = ["camc_scriptpackage.get_creds"]
  value = "${camc_scriptpackage.get_creds.result["Password"]}"
  description="Base64 encoded kubeadmin password"
} 