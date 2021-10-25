module "s3_bucket" {
  source  = "cloudposse/s3-bucket/aws"
  version = "0.43.0"

  for_each = var.buckets

  name = each.key

  acl                     = each.value.acl
  block_public_acls       = each.value.block_public
  block_public_policy     = each.value.block_public
  ignore_public_acls      = each.value.block_public
  restrict_public_buckets = each.value.block_public

  versioning_enabled = each.value.versioning_enabled

  cors_rule_inputs = each.value.cors_rules

  context = module.this.context
}

module "s3_backup_policy_label" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  attributes = ["s3backup"]
  context    = module.this.context
}

resource "aws_iam_policy" "s3_backup_policy" {
  count  = module.this.enabled && var.generate_s3_backup_policy ? 1 : 0
  name   = module.s3_backup_policy_label.id
  path   = "/"
  policy = join("", data.aws_iam_policy_document.s3_backup_access_policy.*.json)
}

data "aws_iam_policy_document" "s3_backup_access_policy" {
  count = module.this.enabled && var.generate_s3_backup_policy ? 1 : 0

  dynamic "statement" {
    for_each = module.this.enabled && var.generate_s3_backup_policy ? var.buckets : {}

    content {
      effect = "Allow"
      actions = [
        "s3:ListBucket"
      ]
      resources = [
        "arn:aws:s3:::${statement.key}"
      ]
    }
  }

  dynamic "statement" {
    for_each = module.this.enabled && var.generate_s3_backup_policy ? var.buckets : {}

    content {
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:GetObjectAcl",
        "s3:GetObjectVersion",
        "s3:GetObjectVersionAcl",
        "s3:GetObjectVersionTagging"
      ]
      resources = [
        "arn:aws:s3:::${statement.key}/*"
      ]
    }
  }
}
