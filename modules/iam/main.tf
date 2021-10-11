#################################################################
# Simplified IAM module for small orgs
#
#################################################################

locals {
  group_names = setproduct(var.accounts, toset(var.groups))
}

resource "aws_iam_group" "group" {
  for_each = local.group_names
  name     = "${each.key[0]}-${each.key[1]}"
}

resource "aws_iam_user" "user" {
  for_each      = var.users
  name          = each.key
  force_destroy = each.value.force_destroy
  tags          = module.this.tags
}

resource "aws_iam_user_login_profile" "user_login" {
  for_each = var.users
  user     = aws_iam_user.user[each.key].name
  pgp_key  = "keybase:${var.keybase_user}"
}

resource "aws_iam_user_group_membership" "group_membership" {
  for_each = aws_iam_group.group # toset(var.groups)
  users    = [for u in var.users : u if contains(u.groups, each.value.name)]
  group    = each.value.name
}


data "aws_iam_policy_document" "assume_admin_role_with_mfa" {
  for_each = var.accounts

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

resource "aws_iam_group_policy" "admin_group_with_mfa_dev" {
  for_each = local_group_names
  name     = "${each.key[0]}-${each.key[1]}-policy"
  group    = "${each.key[0]}-${each.key[1]}"
  policy   = data.aws_iam_policy_document.assume_admin_role_with_mfa[each.key[0]].json
}
