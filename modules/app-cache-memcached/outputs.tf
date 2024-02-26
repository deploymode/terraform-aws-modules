output "endpoint" {
  value       = module.memcached.cluster_configuration_endpoint
  description = "Elasticache memcached endpoint"
}

output "hostname" {
  value       = module.memcached.hostname
  description = "Cluster hostname"
}

# output "port" {
#   value       = module.memcached.port
#   description = "memcached port"
# }

output "security_group_id" {
  value       = module.memcached.security_group_id
  description = "Elasticache memcached security group ID - allows access to memcached cache"
}

output "access_security_group_id" {
  value       = module.memcached_allowed_sg.id
  description = "ID of the security group for use by services which need access to memcached"
}
