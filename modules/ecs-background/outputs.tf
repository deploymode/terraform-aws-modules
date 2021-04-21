output "codepipeline_arn" {
  value       = coalesce(concat([module.ecs_codepipeline.codepipeline_arn, module.ecs_codepipeline_skip_deploy.codepipeline_arn])...)
  description = "CodePipeline ARN"
}

output "ecs_service_security_group_id" {
  description = "Security Group ID of the ECS task"
  value       = module.ecs_task.service_security_group_id
}

output "cloudwatch_log_group_name" {
  description = "ECS Service log group name"
  value       = module.container_label.id
}
