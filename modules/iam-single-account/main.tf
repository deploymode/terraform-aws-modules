#################################################################
# Simplified IAM module for an org running on a single account.
#
# Intended to be run on a single account.
# Uses IAM users only with no assume role.
#################################################################

locals {
  # List of group + policy with a unique id for use in for_each
  group_policy_arns = merge([
    for group, group_data in var.groups : {
      for policy_arn in group_data.policy_arns : join("-", [group, policy_arn]) => {
        group      = group
        policy_arn = policy_arn
      }
    }
  ]...)

  groups_to_users = transpose({ for u, user_data in var.users : u => user_data.groups })

  role_data = { for group, group_data in var.groups : group => {
    policy_arns = group_data.policy_arns
    users       = local.groups_to_users[group]
    } if group_data.create_role
  }

  account_users_group_name = "account-users"

  group_names = toset(concat(keys(var.groups), [local.account_users_group_name]))
}

data "aws_caller_identity" "current" {}

resource "aws_iam_group" "group" {
  for_each = local.group_names
  name     = each.key
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
  for_each = aws_iam_group.group
  name     = "${each.value.name}-membership"
  users    = [for u, user_data in var.users : u if contains(user_data.groups, each.value.name) || each.value.name == local.account_users_group_name]
  group    = each.value.name
}

resource "aws_iam_group_policy_attachment" "group_policy_attachment" {
  for_each = local.group_policy_arns

  # Use this approach to create a dependency
  group      = aws_iam_group.group[each.value.group].name
  policy_arn = each.value.policy_arn
}

resource "aws_iam_group_policy" "users_change_password_policy" {
  name   = "account-users-change-password-policy"
  group  = aws_iam_group.group[local.account_users_group_name].name
  policy = data.aws_iam_policy_document.change_password_policy.json
}

data "aws_iam_policy_document" "change_password_policy" {
  statement {
    actions = [
      "iam:GetAccountPasswordPolicy",
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
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/&{aws:username}"
    ]
  }
}

resource "aws_iam_group_policy" "account_users_manage_keys_policy" {
  name   = "account-users-manage-keys-policy"
  group  = aws_iam_group.group[local.account_users_group_name].name
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

    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/&{aws:username}"]

    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
  }
}

resource "aws_iam_group_policy" "account_users_manage_mfa_policy" {
  name   = "account-users-manage-mfa-policy"
  group  = aws_iam_group.group[local.account_users_group_name].name
  policy = data.aws_iam_policy_document.manage_mfa_policy.json
}

data "aws_iam_policy_document" "manage_mfa_policy" {
  statement {
    sid    = "AllowViewAccountInfo"
    effect = "Allow"
    actions = [
      "iam:ListVirtualMFADevices"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "AllowManageOwnSigningCertificates"
    effect = "Allow"
    actions = [
      "iam:DeleteSigningCertificate",
      "iam:ListSigningCertificates",
      "iam:UpdateSigningCertificate",
      "iam:UploadSigningCertificate"
    ]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/&{aws:username}"]
  }
  statement {
    sid    = "AllowManageOwnSSHPublicKeys"
    effect = "Allow"
    actions = [
      "iam:DeleteSSHPublicKey",
      "iam:GetSSHPublicKey",
      "iam:ListSSHPublicKeys",
      "iam:UpdateSSHPublicKey",
      "iam:UploadSSHPublicKey"
    ]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/&{aws:username}"]
  }
  statement {
    sid    = "AllowManageOwnGitCredentials"
    effect = "Allow"
    actions = [
      "iam:CreateServiceSpecificCredential",
      "iam:DeleteServiceSpecificCredential",
      "iam:ListServiceSpecificCredentials",
      "iam:ResetServiceSpecificCredential",
      "iam:UpdateServiceSpecificCredential"
    ]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/&{aws:username}"]
  }
  statement {
    sid    = "AllowManageOwnVirtualMFADevice"
    effect = "Allow"
    actions = [
      "iam:CreateVirtualMFADevice",
      "iam:DeleteVirtualMFADevice"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:mfa/&{aws:username}"
    ]
  }
  statement {
    sid    = "AllowManageOwnUserMFA"
    effect = "Allow"
    actions = [
      "iam:DeactivateMFADevice",
      "iam:EnableMFADevice",
      "iam:ListMFADevices",
      "iam:ResyncMFADevice"
    ]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/&{aws:username}"]
  }
  statement {
    effect = "Deny"
    not_actions = [
      "iam:CreateVirtualMFADevice",
      "iam:EnableMFADevice",
      "iam:GetUser",
      "iam:ListMFADevices",
      "iam:ListVirtualMFADevices",
      "iam:ResyncMFADevice",
      "sts:GetSessionToken"
    ]
    resources = ["*"]
    condition {
      test     = "BoolIfExists"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["false"]
    }
  }
}

// Custom group policies
resource "aws_iam_group_policy" "additional_policy" {
  for_each = data.aws_iam_policy_document.additional_policy

  group = each.key

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = each.value.json
}

data "aws_iam_policy_document" "additional_policy" {
  for_each = { for group, group_data in var.groups : group => group_data.additional_permissions if length(group_data.additional_permissions) > 0 }

  dynamic "statement" {
    for_each = { for service, policy in each.value : service => policy }

    content {
      sid       = statement.key
      effect    = "Allow"
      actions   = statement.value.permissions
      resources = statement.value.resources
    }
  }
}

resource "aws_iam_account_password_policy" "account_password_policy" {
  count                          = var.provision_account_settings ? 1 : 0
  minimum_password_length        = var.minimum_password_length
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_symbols                = true
  allow_users_to_change_password = var.allow_users_to_change_password
}

#########
# Roles

# data "aws_iam_policy_document" "role_policies" {
#   for_each = local.group_names

#   source_policy_documents = 
# }

module "group_role" {
  source  = "cloudposse/iam-role/aws"
  version = "0.17.0"

  # for_each = { for group, users in local.groups_to_users : group => users if var.groups[group].create_role }
  for_each = local.role_data

  name       = each.key
  attributes = ["role"]

  role_description = "IAM role with same non-user management permissions as ${each.key} group"

  # Roles/users allowed to assume role
  principals = {
    AWS = [for user in each.value.users : aws_iam_user.user[user].arn]
  }

  managed_policy_arns = each.value.policy_arns
  policy_documents = [
    data.aws_iam_policy_document.additional_policy[each.key].json
  ]

  context = module.this.context
}
