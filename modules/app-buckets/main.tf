locals {

  # Generate a list of public paths for each bucket
  bucket_public_paths = {
    for key, value in var.buckets : key => length(value.allowed_public_paths) == 0 ?
    [] :
    [for path in value.allowed_public_paths : "arn:aws:s3:::${module.s3_bucket[key].bucket_id}/${path}"]
  }

  # Generate a list of public resources for each bucket, taking account of the allowed extensions
  bucket_public_resources = {
    for key, value in local.bucket_public_paths : key => length(var.buckets[key].allowed_extensions) == 0 ?
    # TODO: clean this up
    tolist(flatten([value])) :
    tolist(flatten([for path in value : formatlist("%s.%s", path, var.buckets[key].allowed_extensions)]))
  }

  # General list of allowed resource extensions for write policy
  bucket_extensions = {
    for key, value in var.buckets : key => length(value.allowed_extensions) == 0 ?
    ["arn:aws:s3:::${module.s3_bucket[key].bucket_id}/*"] :
    [for ext in value.allowed_extensions : "arn:aws:s3:::${module.s3_bucket[key].bucket_id}/*.${ext}"]
  }
}

module "s3_bucket" {
  source  = "cloudposse/s3-bucket/aws"
  version = "4.10.0"

  for_each = var.buckets

  name = each.key

  bucket_name = var.use_bucket_name_only ? each.value.bucket_name : null

  acl = each.value.acl

  # If block_public is set, it will override the following settings
  block_public_acls       = each.value.block_public_acls || each.value.block_public
  block_public_policy     = each.value.block_public_policy || each.value.block_public
  ignore_public_acls      = each.value.ignore_public_acls || each.value.block_public
  restrict_public_buckets = each.value.restrict_public_buckets || each.value.block_public

  s3_object_ownership = each.value.object_ownership

  versioning_enabled = each.value.versioning_enabled

  cors_configuration = each.value.cors_rules

  context = module.this.context
}

# We can't use the `source_policy_documents` attribute of the `s3` module
# because we need the bucket id to put in the resource filter of the policy
# so we have to attach the bucket policy separately
resource "aws_s3_bucket_policy" "public_resources" {
  for_each = { for k, v in local.bucket_public_resources : k => v if length(v) > 0 }

  bucket = module.s3_bucket[each.key].bucket_id
  policy = module.bucket_policy[each.key].json
}

# This generates JSON for use as the bucket policy
module "bucket_policy" {
  source  = "cloudposse/iam-policy/aws"
  version = "2.0.1"

  for_each = local.bucket_public_resources

  name       = "policy"
  attributes = [each.key, "bucket"]

  iam_policy_enabled = false # Generate JSON only
  description        = "Allows public access to specified paths and extensions for ${module.s3_bucket[each.key].bucket_id}"

  iam_policy = [{
    version   = "2012-10-17"
    policy_id = "s3-bucket-policy-${each.key}"
    statements = [
      {
        sid    = "PublicReadObjects"
        effect = "Allow"
        principals = [
          {
            type        = "AWS"
            identifiers = ["*"]
          }
        ]
        actions = [
          "s3:GetObject",
        ]
        resources  = local.bucket_public_resources[each.key]
        conditions = []
      },

    ]
  }]

  context = module.this.context
}

module "app_bucket_iam_policy_combined" {
  source  = "cloudposse/iam-policy/aws"
  version = "2.0.1"

  count = var.create_policy ? 1 : 0

  name       = "policy"
  attributes = ["app-bucket", "s3"]

  iam_policy_enabled = true
  description        = "Allows app-level access to S3 buckets"

  iam_policy = [{
    version   = "2012-10-17"
    policy_id = "s3-app-bucket"
    statements = concat(
      [
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
      ],
      [for k, b in var.buckets : {
        sid       = format("ListBucket%s", title(k))
        effect    = "Allow"
        actions   = ["s3:ListBucket"]
        resources = ["arn:aws:s3:::${module.s3_bucket[k].bucket_id}"]
      }],
      [for k, b in var.buckets : {
        sid    = format("WriteBucket%s", title(k))
        effect = "Allow"
        actions = compact(concat(
          [
            "s3:PutObject",
            "s3:PutObjectVersionAcl",
            "s3:PutObjectAcl",
            "s3:GetObjectAcl",
            "s3:GetObject",
            "s3:GetObjectVersionAcl",
            "s3:GetObjectVersion"
          ],
          b.allow_delete ? ["s3:DeleteObject"] : []
        ))
        resources = local.bucket_extensions[k]
      }]
    )
  }]

  context = module.this.context
}

# This generates policies to be used by consuming services, e.g. ECS tasks
module "app_bucket_iam_policy_separate" {
  source  = "cloudposse/iam-policy/aws"
  version = "2.0.1"

  for_each = var.create_policy ? var.buckets : {}

  name       = "policy"
  attributes = [each.key, "s3", "bucket"]

  iam_policy_enabled = true
  description        = "Allows app-level access to ${module.s3_bucket[each.key].bucket_id}"

  iam_policy = [{
    version   = "2012-10-17"
    policy_id = "s3-app-bucket"
    statements = [
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
        resources  = local.bucket_extensions[each.key]
        conditions = []
      },
      # Intentionally duplicated
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
  }]

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
