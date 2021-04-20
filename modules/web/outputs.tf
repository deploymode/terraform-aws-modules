output "log_groups" {
  value       = local.log_groups
  description = "ECS log groups"
}

output "ecs_service_security_group_id" {
  value       = module.ecs_task.service_security_group_id
  description = "ECS security group ids"
}

output "host_name" {
  value       = var.hosted_zone_id != "" ? join("", aws_route53_record.default.*.fqdn) : ""
  description = "Public hostname associated with load balancer"
}

output "container_name_nginx" {
  value       = join("-", [module.container_label.id, "nginx"])
  description = "ECS container name for nginx container"
}

output "container_name_php-fpm" {
  value       = join("-", [module.container_label.id, "php-fpm"])
  description = "ECS container name for PHP-FPM container"
}

// Redis

output "redis_endpoint" {
  value       = var.provision_redis_cache ? module.redis.endpoint : ""
  description = "Elasticache Redis endpoint"
}

output "redis_security_group_id" {
  value       = var.provision_redis_cache ? module.redis.security_group_id : ""
  description = "Redis security group ID"
}

output "redis_port" {
  value       = var.provision_redis_cache ? module.redis.port : 0
  description = "Redis port"
}

// DynamoDB

output "dynamodb_table_name" {
  value       = var.provision_dynamodb_cache ? module.dynamodb.table_name : ""
  description = "DynamoDB table name for app cache"
}

output "dynamodb_table_arn" {
  value       = var.provision_dynamodb_cache ? module.dynamodb.table_arn : ""
  description = "DynamoDB table ARN"
}



// SQS

output "queue_arn" {
  description = "The ARN of the SQS queue"
  value       = var.provision_sqs ? module.queue.this_sqs_queue_arn : ""
}

output "queue_name" {
  description = "The name of the SQS queue"
  value       = var.provision_sqs ? module.queue.this_sqs_queue_name : ""
}

// CodePipeline

output "codepipeline_id" {
  description = "CodePipeline ID"
  value       = module.ecs_codepipeline.codepipeline_id
}

output "codepipeline_arn" {
  description = "CodePipeline ARN"
  value       = module.ecs_codepipeline.codepipeline_arn
}
