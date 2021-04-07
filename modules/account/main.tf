resource "aws_organizations_account" "account" {
  name      = module.this.name
  email     = format(var.account_email, module.this.name)
  role_name = var.account_role_name

  lifecycle {
    ignore_changes = [role_name]
  }
}
