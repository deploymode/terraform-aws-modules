output "name" {
  value       = module.role.name
  description = "The name of the IAM role created"
}

output "role_id" {
  value       = module.role.id
  description = "The stable and unique string identifying the role"
}

output "role_arn" {
  value       = module.role.arn
  description = "The ARN of the IAM role"
}

output "policy" {
  value       = module.role.policy
  description = "Role policy document in json format. Outputs always, independent of `enabled` variable"
}
