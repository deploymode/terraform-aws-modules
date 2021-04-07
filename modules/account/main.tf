resource "aws_organizations_account" "account" {
  name      = module.this.stage
  email     = format(var.account_email, module.this.stage)
  role_name = var.account_role_name

  lifecycle {
    ignore_changes = [role_name]
  }
}
