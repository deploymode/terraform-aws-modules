#################################################################
# Creates users for external services, e.g. Bitnami 
#
#################################################################

locals {
  user_inline_policies = flatten([
    for user, user_data in var.users : [
      for policy, policy_data in user_data.inline_policy_map : {
        user_name   = user
        policy_name = policy
        data        = policy_data
      }
    ]
    ]
  )
}

module "user" {
  source  = "cloudposse/iam-system-user/aws"
  version = "1.0.0"

  for_each = var.users

  ssm_enabled           = true
  force_destroy         = each.value.force_destroy
  create_iam_access_key = each.value.generate_access_key
  ssm_base_path         = each.value.ssm_base_path == null ? "/${module.this.namespace}/${module.this.stage}/${module.this.environment}/system_users/" : each.value.ssm_base_path
  policy_arns_map       = each.value.managed_policy_arn_map
  inline_policies_map   = { for user_policy in local.user_inline_policies : "${user_policy.user_name}.${user_policy.policy_name}" => data.aws_iam_policy_document.user_policy["${user_policy.user_name}.${user_policy.policy_name}"].json }

  context = module.this.context
}

data "aws_iam_policy_document" "user_policy" {

  # for_each = { for user, user_data in var.users : user => { for policy, policy_data in user_data.inline_policy_map : policy => policy_data } }
  for_each = {
    for user_policy in local.user_inline_policies : "${user_policy.user_name}.${user_policy.policy_name}" => user_policy
  }

  statement {
    actions   = each.value.data.actions
    resources = each.value.data.resources
  }
}
