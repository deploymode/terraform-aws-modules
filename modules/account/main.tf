resource "aws_organizations_organization" "this" {
  aws_service_access_principals = var.org_service_access_principals
  enabled_policy_types          = var.org_enabled_policy_types
  feature_set                   = var.org_feature_set
}

locals {
  organization_root_account_id      = aws_organizations_organization.this.roots[0].id
  organization_id                   = aws_organizations_organization.this.id
  organization_arn                  = aws_organizations_organization.this.arn
  organization_master_account_id    = aws_organizations_organization.this.master_account_id
  organization_master_account_arn   = aws_organizations_organization.this.master_account_arn
  organization_master_account_email = aws_organizations_organization.this.master_account_email
}

resource "aws_organizations_account" "account" {
  for_each  = toset(var.accounts)
  name      = each.value.name
  email     = format(var.account_email_format, each.key)
  role_name = var.account_role_name

  lifecycle {
    ignore_changes = [role_name]
  }
}
