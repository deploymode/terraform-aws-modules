output "account_arn" {
  value = aws_organizations_account.account.arn
}

output "account_id" {
  value = aws_organizations_account.account.id
}

output "organization_account_access_role" {
  value = "${local.organization_account_access_role}"
}
