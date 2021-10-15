
// Role to allow primary account role to assume role in this account for managing DNS
module "dns_role" {
  source  = "cloudposse/iam-role/aws"
  version = "0.13.0"

  context = module.this.context
  name    = "dns"

  enabled = module.this.enabled && var.provision_dns_role

  policy_description = "Allow another account to manage DNS in this account"
  role_description   = "IAM role with permissions to manage DNS"

  # Roles allowed to assume role
  principals = {
    AWS = [
      var.dns_role_arn
    ]
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
