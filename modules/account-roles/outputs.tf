output "dns_role_arn" {
  value = module.dns_role.arn
}

output "admin_role_arn" {
  value = module.admin_role.arn
}

output "role_arns" {
  value = {for role in module.role : role.name => role.arn}
}