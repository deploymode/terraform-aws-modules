output "endpoint" {
  value       = module.redis.endpoint
  description = "Elasticache Redis endpoint"
}

output "port" {
  value       = module.redis.port
  description = "Redis port"
}

output "security_group_id" {
  value       = module.redis.security_group_id
  description = "Elasticache Redis security group ID - allows access to Redis cache"
}

output "access_security_group_id" {
  value       = module.redis_allowed_sg.id
  description = "ID of the security group for use by services which need access to Redis"
}
