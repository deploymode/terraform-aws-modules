

module "oidc_provider" {
  source  = "philips-labs/github-oidc/aws//modules/provider"
  version = "0.8.1"
}

module "repo_oidc_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  for_each = var.github_repositories

  name = each.key

  context = module.this.context
}

module "repo_oidc" {
  source  = "philips-labs/github-oidc/aws"
  version = "0.8.1"

  for_each = var.github_repositories

  openid_connect_provider_arn = module.oidc_provider.openid_connect_provider.arn
  repo                        = each.key
  role_name                   = module.repo_oidc_label[each.key].id

  default_conditions   = each.value.default_conditions
  github_environments  = each.value.github_environments
  repo_mainline_branch = each.value.default_branch

  role_policy_arns = [module.iam_policy[each.key].policy_arn]

  # add extra conditions, will be merged with the default_conditions
  # conditions = [{
  #   test     = "StringLike"
  #   variable = "token.actions.githubusercontent.com:sub"
  #   values   = ["repo:my-org/my-repo:pull_request"]
  # }]

}

data "aws_ecr_repository" "default" {
  for_each = var.github_repositories

  name = each.value.ecr_repository_name
}

module "iam_policy" {
  source  = "cloudposse/iam-policy/aws"
  version = "2.0.2"

  for_each = var.github_repositories

  name = each.key

  # Actually create the policy
  iam_policy_enabled = true

  iam_policy = [{
    version   = "2012-10-17"
    policy_id = "ecr"
    statements = [
      {
        effect = "Allow"
        actions = [
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
        ]
        resources = [data.aws_ecr_repository.default[each.key].arn]
      },
      {
        effect    = "Allow"
        actions   = ["ecr:GetAuthorizationToken"]
        resources = ["*"]
      }
    ]
  }]

  context = module.this.context
}
