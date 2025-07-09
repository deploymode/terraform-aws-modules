#################################################################
# Simplified IAM module for small orgs
#
# Intended to be run from master account
#################################################################

locals {

  defaults = {
    max_session_duration = 3600
  }

  # Create group names by prefixing account name
  group_names = {
    for tuple in setproduct(keys(var.accounts), toset(var.groups)) : "${var.namespace}-${tuple[0]}-${tuple[1]}" => {
      account = tuple[0]
      group   = tuple[1]
    }
  }

  admin_group_names = {
    for group, group_data in local.group_names : group => group_data if group_data.group == "admin"
  }

  other_group_names = {
    for group, group_data in local.group_names : group => group_data if group_data.group != "admin"
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

# // BEGIN USERS AND GROUPS

resource "aws_iam_group" "group" {
  for_each = local.group_names
  name     = each.key
}

resource "aws_iam_user" "user" {
  for_each = var.users

  name          = each.key
  force_destroy = each.value.force_destroy
  tags          = module.this.tags
}

resource "aws_iam_user_login_profile" "user_login" {
  for_each = aws_iam_user.user

  user    = each.value.name
  pgp_key = var.encryption_key
}

resource "aws_iam_access_key" "user_key" {
  for_each = { for u, user_data in var.users : u => user_data if user_data.generate_access_key }

  user    = each.key
  pgp_key = var.encryption_key
}

resource "aws_iam_group_membership" "group_membership" {
  for_each = aws_iam_group.group

  name  = "${each.value.name}-membership"
  users = [for u, user_data in var.users : u if contains(user_data.groups, each.value.name)]
  group = each.value.name
}

resource "aws_iam_group_membership" "master_account_users_group_membership" {
  name  = "master-account-users-group-membership"
  users = keys(var.users)
  group = aws_iam_group.master_account_users.name
}

# // END USERS AND GROUPS

# // BEGIN ROLES AND POLICIES

# A policy document to allow role members to assume an admin role in each account
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

# A group policy to allow role members to assume an admin role in other accounts
resource "aws_iam_group_policy" "admin_group_with_mfa_policy" {
  for_each = local.admin_group_names

  name   = "${each.key}-policy"
  group  = each.key
  policy = data.aws_iam_policy_document.assume_admin_role_with_mfa[each.value.account].json
}

# Allows group users to assume the role associated with the group 
data "aws_iam_policy_document" "assume_group_role_with_mfa" {
  for_each = local.other_group_names

  statement {
    actions = [
      "sts:AssumeRole",
    ]

    resources = [module.account_assume_role[each.key].arn]

    # disable for cli use
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }

    effect = "Allow"
  }
}

# A group policy to allow role members to assume an arbitrary role in other accounts
resource "aws_iam_group_policy" "other_group_with_mfa_policy" {
  for_each = local.other_group_names

  name   = "${each.key}-policy"
  group  = each.key
  policy = data.aws_iam_policy_document.assume_group_role_with_mfa[each.key].json
}


// Role to allow users in the master account to assume a role in another account

data "aws_iam_policy_document" "account_assume_role" {
  for_each = local.other_group_names

  statement {
    actions = [
      "sts:AssumeRole",
      "sts:SetSourceIdentity",
      "sts:TagSession",
    ]

    resources = ["arn:aws:iam::${var.accounts[each.value.account].account_id}:role/${var.namespace}-${each.value.account}-${each.value.group}"]

    effect = "Allow"
  }
}

module "account_assume_role" {
  source  = "cloudposse/iam-role/aws"
  version = "0.16.2"

  for_each = local.other_group_names

  name = each.key

  enabled = module.this.enabled

  role_description = "Allows users in ${each.value.group} group to assume role in ${each.value.account} account"

  # Roles allowed to assume role
  principals = {
    AWS = [
      # todo: improve this with something like
      #  condition {
      #   test     = "ArnLike"
      #   variable = "aws:PrincipalArn"
      #   values   = local.allowed_roles
      # }
      "arn:aws:iam::${var.accounts["master"].account_id}:root"
      # "arn:aws:iam::${var.accounts["master"].account_id}:role/${each.key}"
      # "arn:aws:iam::${var.accounts[each.value.account].account_id}:role/${each.key}"
    ]
  }

  policy_documents = [
    data.aws_iam_policy_document.account_assume_role[each.key].json
  ]

  max_session_duration = lookup(var.account_settings, "master", { max_session_duration = local.defaults.max_session_duration }).max_session_duration

  # context = module.this.context
}

# // END GROUP ROLES AND POLICIES


# // BEGING MASTER ACCOUNT ROLES, POLICIES, AND GROUPS
// **
// Master Account access
// **

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

resource "aws_iam_role_policy_attachment" "role_policy_attachment_admin" {
  role       = module.master_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

## // END MASTER ACCOUNT ROLES, POLICIES, AND GROUPS


# // BEGIN MASTER ACCOUNT USERS, GROUPS AND POLICIES

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
      "iam:GetUser",
      "iam:GetLoginProfile"
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
      "arn:aws:iam::${local.master_account_with_role.account_id}:mfa/*",
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
      "arn:aws:iam::${local.master_account_with_role.account_id}:mfa/*",
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
