output "organization_id" {
  value       = local.organization_id
  description = "Organization ID"
}

output "organization_arn" {
  value       = local.organization_arn
  description = "Organization ARN"
}

output "organization_master_account_id" {
  value       = local.organization_master_account_id
  description = "Organization master account ID"
}

output "organization_master_account_arn" {
  value       = local.organization_master_account_arn
  description = "Organization master account ARN"
}

output "organization_master_account_email" {
  value       = local.organization_master_account_email
  description = "Organization master account email"
}

output "account_arns" {
  value = values(aws_organizations_account.account)[*]["arn"]
}

output "account_ids" {
  value = values(aws_organizations_account.account)[*]["id"]
}

output "account_name_id_map" {
  value = { for a in var.accounts : a => {
    account_id           = aws_organizations_account.account[a]["id"]
    org_access_role_name = aws_organizations_account.account[a]["role_name"]
    }
  }
}

output "organization_account_access_roles" {
  value = values(aws_organizations_account.account)[*]["role_name"]
}
