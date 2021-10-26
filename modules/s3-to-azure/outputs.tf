# ecs service ARN

output "ecs_cluster_arn" {
  value       = module.cluster.arn
  description = "ARN of ECS cluster"
}

output "ecs_service_codepipeline_arn" {
  value       = module.service.codepipeline_arn
  description = "ARN of CodePipeline service"
}

output "ecs_service_security_group_id" {
  value       = module.service.ecs_service_security_group_id
  description = "Security group assigned to ECS service"
}

output "ecs_service_cloudwatch_log_group_name" {
  description = "ECS Service log group name"
  value       = module.service.cloudwatch_log_group_name
}

output "enabled" {
  value       = module.this.enabled
  description = "Is module enabled?"
}
