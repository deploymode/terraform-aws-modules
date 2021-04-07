output "log_groups" {
  value       = local.log_groups
  description = "ECS log groups"
}

output "ecs_service_security_group_id" {
  value       = module.ecs_alb_service_task.service_security_group_id
  description = "ECS security group ids"
}

output "host_name" {
  value       = var.hosted_zone_id != "" ? join("", aws_route53_record.default.*.fqdn) : ""
  description = "Public hostname associated with load balancer"
}
