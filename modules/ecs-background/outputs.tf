output "codepipeline_arn" {
  value       = module.ecs_codepipeline.codepipeline_arn
  description = "CodePipeline ARN"
}

output "ecs_service_security_group_id" {
  description = "Security Group ID of the ECS task"
  value       = module.ecs_alb_service_task.service_security_group_id
}

output "cloudwatch_log_group_name" {
  description = "ECS Service log group name"
  value       = module.container_label.id
}
