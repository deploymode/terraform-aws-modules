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
  value       = var.provision_redis_cache ? module.redis_allowed_sg.id : ""
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

output "codestar_connection_arn" {
  description = "Codestar connection ARN"
  value       = coalesce(var.codestar_connection_arn, join("", aws_codestarconnections_connection.default.*.arn))
}

// IAM

output "app_bucket_policy_arn" {
  description = "ARN of IAM policy allowing access to S3 buckets used by app"
  value       = { for key, policy in aws_iam_policy.app_bucket_iam_policy : key => policy.arn }
}

// App

output "application_endpoint" {
  description = "HTTP endpoint for application"
  value       = local.app_fqdn
}

// Frontend website

output "frontend_hostname" {
  value       = var.create_frontend_website ? local.frontend_fqdn : ""
  description = "Frontend web endpoint"
}

output "frontend_bucket_name" {
  description = "Name of S3 bucket used to store frontend website"
  value       = var.create_frontend_website ? module.frontend_web.s3_bucket : ""
}

output "s3_bucket_domain_name" {
  value       = var.create_frontend_website ? module.frontend_web.s3_bucket_domain_name : ""
  description = "Name of website bucket"
}

output "s3_bucket_arn" {
  value       = var.create_frontend_website ? module.frontend_web.s3_bucket_arn : ""
  description = "ARN of website bucket"
}
