module "s3_bucket" {
  source  = "cloudposse/s3-bucket/aws"
  version = "2.0.3"

  for_each = var.buckets

  name = each.key

  bucket_name = var.use_bucket_name_only ? each.value.bucket_name : null

  acl                     = each.value.acl
  block_public_acls       = each.value.block_public
  block_public_policy     = each.value.block_public
  ignore_public_acls      = each.value.block_public
  restrict_public_buckets = each.value.block_public

  versioning_enabled = each.value.versioning_enabled

  cors_rule_inputs = each.value.cors_rules

  context = module.this.context
}

module "app_bucket_iam_policy" {
  source  = "cloudposse/iam-policy/aws"
  version = "0.3.0"

  for_each = var.create_policy ? var.buckets : {}

  name       = "policy"
  attributes = [each.key, "s3"]

  iam_policy_enabled = true
  description        = "Allows app-level access to ${module.s3_bucket[each.key].bucket_id}"

  iam_policy_statements = [
    {
      sid        = "ListBucket"
      effect     = "Allow"
      actions    = ["s3:ListBucket"]
      resources  = ["arn:aws:s3:::${module.s3_bucket[each.key].bucket_id}"]
      conditions = []
    },
    {
      sid    = "WriteBucket"
      effect = "Allow"
      actions = compact(concat([
        "s3:PutObject",
        "s3:PutObjectVersionAcl",
        "s3:PutObjectAcl",
        "s3:GetObjectAcl",
        "s3:GetObject",
        "s3:GetObjectVersionAcl",
        "s3:GetObjectVersion"
        ],
        each.value.allow_delete ?
        [
          "s3:DeleteObject"
        ]
      : []))
      resources  = ["arn:aws:s3:::${module.s3_bucket[each.key].bucket_id}/*"]
      conditions = []
    },
    # TODO: move this out so it's not duplicated
    {
      sid    = "ListBuckets"
      effect = "Allow"
      actions = [
        "s3:ListAllMyBuckets",
        "s3:HeadBucket"
      ]
      resources  = ["*"]
      conditions = []
    }
  ]

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
