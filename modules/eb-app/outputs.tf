output "elastic_beanstalk_application_name" {
  value       = module.elastic_beanstalk_application.elastic_beanstalk_application_name
  description = "Elastic Beanstalk Application name"
}

output "elastic_beanstalk_environment_hostname" {
  value       = { for k in keys(var.environment_settings) : k => module.elastic_beanstalk_environment[k].hostname }
  description = "DNS hostname"
}

output "elastic_beanstalk_environment_id" {
  description = "ID of the Elastic Beanstalk environment"
  value       = { for k in keys(var.environment_settings) : k => module.elastic_beanstalk_environment[k].id }
}

output "elastic_beanstalk_environment_name" {
  value       = { for k in keys(var.environment_settings) : k => module.elastic_beanstalk_environment[k].name }
  description = "Name"
}

output "elastic_beanstalk_environment_security_group_id" {
  value       = { for k in keys(var.environment_settings) : k => module.elastic_beanstalk_environment[k].security_group_id }
  description = "Elastic Beanstalk environment Security Group ID"
}

output "elastic_beanstalk_environment_security_group_arn" {
  value       = { for k in keys(var.environment_settings) : k => module.elastic_beanstalk_environment[k].security_group_arn }
  description = "Elastic Beanstalk environment Security Group ARN"
}

output "elastic_beanstalk_environment_security_group_name" {
  value       = { for k in keys(var.environment_settings) : k => module.elastic_beanstalk_environment[k].security_group_name }
  description = "Elastic Beanstalk environment Security Group name"
}

output "elastic_beanstalk_environment_elb_zone_id" {
  value       = { for k in keys(var.environment_settings) : k => module.elastic_beanstalk_environment[k].elb_zone_id }
  description = "ELB zone id"
}

output "elastic_beanstalk_environment_ec2_instance_profile_role_name" {
  value       = { for k in keys(var.environment_settings) : k => module.elastic_beanstalk_environment[k].ec2_instance_profile_role_name }
  description = "Instance IAM role name"
}

output "elastic_beanstalk_environment_tier" {
  description = "The environment tier"
  value       = { for k in keys(var.environment_settings) : k => module.elastic_beanstalk_environment[k].tier }
}

output "elastic_beanstalk_environment_application" {
  description = "The Elastic Beanstalk Application specified for this environment"
  value       = { for k in keys(var.environment_settings) : k => module.elastic_beanstalk_environment[k].application }
}

output "elastic_beanstalk_environment_setting" {
  description = "Settings specifically set for this environment"
  value       = { for k in keys(var.environment_settings) : k => module.elastic_beanstalk_environment[k].setting }
}

# output "elastic_beanstalk_environment_all_settings" {
#   description = "List of all option settings configured in the environment. These are a combination of default settings and their overrides from setting in the configuration"
#   value       = { for k in keys(var.environment_settings) : k => module.elastic_beanstalk_environment[k].all_settings }
# }

output "elastic_beanstalk_environment_endpoint" {
  description = "Fully qualified DNS name for the environment"
  value       = { for k in keys(var.environment_settings) : k => module.elastic_beanstalk_environment[k].endpoint }
}

output "elastic_beanstalk_environment_autoscaling_groups" {
  description = "The autoscaling groups used by this environment"
  value       = { for k in keys(var.environment_settings) : k => module.elastic_beanstalk_environment[k].autoscaling_groups }
}

output "elastic_beanstalk_environment_instances" {
  description = "Instances used by this environment"
  value       = { for k in keys(var.environment_settings) : k => module.elastic_beanstalk_environment[k].instances }
}

output "elastic_beanstalk_environment_launch_configurations" {
  description = "Launch configurations in use by this environment"
  value       = { for k in keys(var.environment_settings) : k => module.elastic_beanstalk_environment[k].launch_configurations }
}

output "elastic_beanstalk_environment_load_balancers" {
  description = "Elastic Load Balancers in use by this environment"
  value       = { for k in keys(var.environment_settings) : k => module.elastic_beanstalk_environment[k].load_balancers }
}

output "elastic_beanstalk_environment_queues" {
  description = "SQS queues in use by this environment"
  value       = { for k in keys(var.environment_settings) : k => module.elastic_beanstalk_environment[k].queues }
}

output "elastic_beanstalk_environment_triggers" {
  description = "Autoscaling triggers in use by this environment"
  value       = { for k in keys(var.environment_settings) : k => module.elastic_beanstalk_environment[k].triggers }
}

// SSH keypair

output "key_name" {
  value       = var.create_key_pair ? module.ssh_key_pair.key_name : ""
  description = "Name of SSH key"
}

output "public_key" {
  value       = var.create_key_pair ? module.ssh_key_pair.public_key : ""
  description = "Content of the generated public key"
}

output "public_key_filename" {
  value       = var.create_key_pair ? module.ssh_key_pair.public_key_filename : ""
  description = "Public Key Filename"
}

output "private_key_filename" {
  value       = var.create_key_pair ? module.ssh_key_pair.private_key_filename : ""
  description = "Private Key Filename"
}
