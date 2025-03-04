output "codepipeline_arn" {
  value       = module.ecs_codepipeline.codepipeline_arn
  description = "CodePipeline ARN"
}

output "ecs_service_security_group_id" {
  description = "Security Group ID of the ECS task"
  value       = module.ecs_task.service_security_group_id
}

output "ecs_task_definition_family" {
  description = "Family of ECS task definition"
  value       = module.ecs_task.task_definition_family
}

output "log_groups" {
  value       = local.log_groups
  description = "ECS log groups"
}

output "build_log_groups" {
  value       = local.build_log_groups
  description = "Codebuild log groups"
}

output "ecs_task_definition_revision" {
  description = "ECS task definition revision"
  value       = module.ecs_task.task_definition_revision
}
