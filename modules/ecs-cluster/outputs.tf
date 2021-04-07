output "id" {
  value       = aws_ecs_cluster.fargate_cluster.*.id
  description = "Cluster ID"
}

output "arn" {
  value       = aws_ecs_cluster.fargate_cluster.*.arn
  description = "Cluster ARN"
}

output "name" {
  value       = aws_ecs_cluster.fargate_cluster.*.name
  description = "Cluster Name"
}
