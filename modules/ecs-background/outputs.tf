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

output "ecs_task_run_policy_arn" {
  description = "ARN of the policy to allow running ECS tasks"
  value       = one(module.ecs_task_run_policy[*]["policy_arn"])
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

output "ecr_repository_name" {
  description = "ECR repository name"
  value       = module.ecr.repository_name
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = module.ecr.repository_url
}
