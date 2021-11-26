output "log_groups" {
  value       = local.log_groups
  description = "ECS log groups"
}

// ECR

output "repository_url_map" {
  value       = module.ecr.repository_url_map
  description = "Map of repository names to repository URLs"
}

// ECS

output "ecs_service_security_group_id" {
  value       = module.ecs_task.service_security_group_id
  description = "ECS security group ids"
}

output "ecs_task_role_name" {
  description = "ECS Task role name"
  value       = module.ecs_task.task_role_name
}

output "ecs_task_role_arn" {
  description = "ECS Task role ARN"
  value       = module.ecs_task.task_role_arn
}

output "ecs_task_role_id" {
  description = "ECS Task role id"
  value       = module.ecs_task.task_role_id
}

output "ecs_task_definition_revision" {
  description = "ECS task definition revision"
  value       = module.ecs_task.task_definition_revision
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

output "redis_port" {
  value       = var.provision_redis_cache ? module.redis.port : 0
  description = "Redis port"
}

output "redis_security_group_id" {
  value       = var.provision_redis_cache ? module.redis.security_group_id : ""
  description = "Elasticache Redis security group ID - allows access to Redis cache"
}

output "redis_access_security_group_id" {
  value       = var.provision_redis_cache ? join("", aws_security_group.redis_allowed.*.id) : ""
  description = "ID of the security group for use by services which need access to Redis"
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

output "dynamodb_access_policy_arn" {
  value       = var.provision_dynamodb_cache ? join("", aws_iam_policy.dynamodb_access_policy.*.arn) : ""
  description = "Policy to allow access to DynamoDB table for app cache"
}

// Email

output "email_sending_policy_arn" {
  value       = var.allow_email_sending ? join("", aws_iam_policy.email_policy.*.arn) : ""
  description = "Policy to allow sending email via SES"
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

// IAM

output "app_bucket_policy_arn" {
  description = "ARN of IAM policy allowing access to S3 buckets used by app"
  value       = [for v in aws_iam_policy.app_bucket_iam_policy : v.arn]
}
