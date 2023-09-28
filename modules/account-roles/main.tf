
// Role to allow primary account role to assume role in this account for managing DNS
module "dns_role" {
  source  = "cloudposse/iam-role/aws"
  version = "0.16.02"

  context = module.this.context
  name    = "dns"

  enabled = module.this.enabled && var.provision_dns_role

  policy_description = "Allow another account to manage DNS in this account"
  role_description   = "IAM role with permissions to manage DNS"

  # Roles allowed to assume role
  principals = {
    AWS = var.dns_assume_role_arns
  }

  policy_documents = [
    data.aws_iam_policy_document.dns_policy.json
  ]
}

data "aws_iam_policy_document" "dns_policy" {
  statement {
    sid = "dns"

    actions = [
      "route53:CreateHostedZone",
      "route53:UpdateHostedZoneComment",
      "route53:GetHostedZone",
      "route53:ListHostedZones",
      "route53:DeleteHostedZone",
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets",
      "route53:GetHostedZoneCount",
      "route53:GetChange",
      "route53:ListHostedZonesByName",
      "route53:ListTagsForResource",
      "route53:ChangeTagsForResource"
    ]

    resources = [
      "*"
    ]
  }

}

// Role to allow primary account role to assume role in this account for performing Admin functions 
module "admin_role" {
  source  = "cloudposse/iam-role/aws"
  version = "0.16.2"

  context = module.this.context
  name    = "admin"

  enabled = module.this.enabled && var.provision_admin_role

  policy_description = "Admin access"
  role_description   = "IAM role with permissions to perform admin functions"

  # Roles/users allowed to assume role
  principals = {
    AWS = var.admin_assume_role_arns
  }

  max_session_duration = var.admin_session_duration

  assume_role_conditions = [{
    test     = "Bool"
    variable = "aws:MultiFactorAuthPresent"
    values   = ["true"]
  }]

  policy_document_count = 0
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess"
  ]
}

// Role to allow primary account role to assume role in this account for performing Admin functions 
module "role" {
  for_each = var.roles

  source  = "cloudposse/iam-role/aws"
  version = "0.16.2"

  name    = each.key

  enabled = module.this.enabled

  policy_description = "${each.key} access"
  role_description   = each.value.description 

  # Roles/users allowed to assume role
  principals = {
    AWS = compact(concat(each.value.assume_role_arns,
      [for name in each.value.assume_role_names : "arn:aws:iam::${var.identity_account_id}:role/${module.this.stage}-${name}"]
    ))
  }

  max_session_duration = each.value.max_session_duration

  assume_role_conditions = each.value.enforce_mfa ? [{
    test     = "Bool"
    variable = "aws:MultiFactorAuthPresent"
    values   = ["true"]
  }] : []

  policy_document_count = 0
  managed_policy_arns = each.value.managed_policy_arns

  context = module.this.context
}
