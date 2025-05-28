output "ecs_event_cloudwatch_log_groups" {
  value       = { for key, log_group in module.ecs_event_logs : log_group.log_group_name => log_group.log_group_arn }
  description = "ECS Event CloudWatch Log Groups"
}
