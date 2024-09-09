#################################################################
# Simplified IAM module for small orgs
#
# Intended to be run from master account
#################################################################

locals {

  defaults = {
    max_session_duration = 3600
  }

  group_names = {
    for tuple in setproduct(keys(var.accounts), toset(var.groups)) : "${tuple[0]}-${tuple[1]}" => {
      account = tuple[0]
      group   = tuple[1]
    }
  }

  # Add the admin role for the master account, since it wasn't created in the `account` module
  master_account_with_role = lookup(var.accounts, var.master_account_name)
  accounts = merge(var.accounts, {
    (var.master_account_name) = {
      account_id           = local.master_account_with_role.account_id
      org_access_role_name = module.master_admin_role.name
    }
    }
  )
}

resource "aws_iam_group" "group" {
  for_each = local.group_names
  name     = each.key # "${each.key}-${each.value}"
}

resource "aws_iam_user" "user" {
  for_each      = var.users
  name          = each.key
  force_destroy = each.value.force_destroy
  tags          = module.this.tags
}

resource "aws_iam_user_login_profile" "user_login" {
  for_each = aws_iam_user.user
  user     = each.value.name
  pgp_key  = var.encryption_key
}

resource "aws_iam_access_key" "user_key" {
  for_each = { for u, user_data in var.users : u => user_data if user_data.generate_access_key }
  user     = each.key
  pgp_key  = var.encryption_key
}

resource "aws_iam_group_membership" "group_membership" {
  for_each = aws_iam_group.group # toset(var.groups)
  name     = "${each.value.name}-membership"
  users    = [for u, user_data in var.users : u if contains(user_data.groups, each.value.name)]
  group    = each.value.name
}

data "aws_iam_policy_document" "assume_admin_role_with_mfa" {
  for_each = local.accounts

  statement {
    actions = [
      "sts:AssumeRole",
    ]

    resources = [
      "arn:aws:iam::${each.value.account_id}:role/${each.value.org_access_role_name}",
    ]

    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }

    effect = "Allow"
  }
}

resource "aws_iam_group_policy" "admin_group_with_mfa_policy" {
  for_each = local.group_names
  name     = "${each.key}-policy"
  group    = each.key
  policy   = data.aws_iam_policy_document.assume_admin_role_with_mfa[each.value.account].json
}

resource "aws_iam_role_policy_attachment" "role_policy_attachment_admin" {
  role       = module.master_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role_policy_attachment" "role_policy_attachment_admin_billing" {
  role       = module.master_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSBillingReadOnlyAccess"
  // Full access to Billing (arn:aws:iam::aws:policy/job-function/Billing)
}

// Role to allow users in the master account to assume role
module "master_admin_role" {
  source  = "cloudposse/iam-role/aws"
  version = "0.16.2"

  context = module.this.context
  name    = "admin"

  enabled = module.this.enabled && var.provision_master_admin_role

  policy_document_count = 0

  policy_description = "Allow admin access to master account"
  role_description   = "IAM role with admin permissions"

  # Roles allowed to assume role
  principals = {
    AWS = [
      "arn:aws:iam::${var.accounts["master"].account_id}:root"
    ]
  }

  max_session_duration = lookup(var.account_settings, "master", { max_session_duration = local.defaults.max_session_duration }).max_session_duration
}

# Group to control password policy for users in master account
resource "aws_iam_group" "master_account_users" {
  name = "master-account-users"
}

resource "aws_iam_group_policy" "master_users_change_password_policy" {
  name   = "master-account-users-change-password-policy"
  group  = aws_iam_group.master_account_users.name
  policy = data.aws_iam_policy_document.change_password_policy.json
}

data "aws_iam_policy_document" "change_password_policy" {
  statement {
    actions = [
      "iam:GetAccountPasswordPolicy"
    ]

    resources = [
      "*"
    ]
  }
  statement {
    actions = [
      "iam:ChangePassword",
      "iam:GetUser"
    ]

    resources = [
      "arn:aws:iam::${local.master_account_with_role.account_id}:user/&{aws:username}"
    ]
  }
}

resource "aws_iam_group_policy" "master_users_manage_keys_policy" {
  name   = "master-account-users-manage-keys-policy"
  group  = aws_iam_group.master_account_users.name
  policy = data.aws_iam_policy_document.manage_keys_policy.json
}

data "aws_iam_policy_document" "manage_keys_policy" {
  statement {
    actions = [
      "iam:DeleteAccessKey",
      "iam:GetAccessKeyLastUsed",
      "iam:UpdateAccessKey",
      "iam:GetUser",
      "iam:CreateAccessKey",
      "iam:ListAccessKeys",
    ]

    resources = ["arn:aws:iam::${local.master_account_with_role.account_id}:user/&{aws:username}"]

    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
  }
}

resource "aws_iam_group_policy" "master_users_manage_mfa_policy" {
  name   = "master-account-users-manage-mfa-policy"
  group  = aws_iam_group.master_account_users.name
  policy = data.aws_iam_policy_document.manage_mfa_policy.json
}

data "aws_iam_policy_document" "manage_mfa_policy" {
  statement {
    effect = "Allow"
    actions = [
      "iam:ListMFADevices",
      "iam:ListVirtualMFADevices",
      "iam:ListUsers"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "iam:CreateVirtualMFADevice",
      "iam:EnableMFADevice",
      "iam:ResyncMFADevice"
    ]
    resources = [
      "arn:aws:iam::${local.master_account_with_role.account_id}:mfa/&{aws:username}",
      "arn:aws:iam::${local.master_account_with_role.account_id}:user/&{aws:username}"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "iam:DeactivateMFADevice",
      "iam:DeleteVirtualMFADevice"
    ]
    resources = [
      "arn:aws:iam::${local.master_account_with_role.account_id}:mfa/&{aws:username}",
      "arn:aws:iam::${local.master_account_with_role.account_id}:user/&{aws:username}"
    ]
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
  }
  # statement {
  #   effect = "Deny"
  #   actions = [
  #     "iam:CreateVirtualMFADevice",
  #     "iam:EnableMFADevice",
  #     "iam:GetUser",
  #     "iam:ListMFADevices",
  #     "iam:ListVirtualMFADevices",
  #     "iam:ResyncMFADevice",
  #     "sts:GetSessionToken"
  #   ]
  #   resources = ["*"]
  #   condition {
  #     test     = "BoolIfExists"
  #     variable = "aws:MultiFactorAuthPresent"
  #     values   = ["false"]
  #   }
  # }
}

resource "aws_iam_group_membership" "master_account_users_group_membership" {
  name  = "master-account-users-group-membership"
  users = keys(var.users)
  group = aws_iam_group.master_account_users.name
}
