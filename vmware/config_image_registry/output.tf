output "dependsOn" { 
	value = "${null_resource.configured_image_registry.id}"
	description="Output Parameter when Module Complete"
}