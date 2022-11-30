###
#
# Creates buckets, IAM roles and policies to receive S3 replication.
#
###

###
#
# Creates IAM roles and policies to allow replication
#
###

resource "aws_iam_role" "replication" {
  provider = aws.source
  count    = module.this.enabled ? 1 : 0
  name     = module.this.id

  description = "Allow S3 to assume a role for replication"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "s3_replication" {
  provider = aws.source
  name     = module.this.id
  policy   = data.aws_iam_policy_document.replication.json
  role     = join("", aws_iam_role.replication.*.name)
}

data "aws_iam_policy_document" "replication" {
  provider = aws.source
  dynamic "statement" {
    for_each = module.this.enabled ? var.bucket_names : {}

    content {
      effect = "Allow"
      actions = [
        "s3:GetReplicationConfiguration",
        "s3:ListBucket"
      ]
      resources = [
        "arn:aws:s3:::${statement.key}"
      ]
    }
  }

  dynamic "statement" {
    for_each = module.this.enabled ? var.bucket_names : {}

    content {
      effect = "Allow"
      actions = [
        "s3:GetObjectVersionForReplication",
        "s3:GetObjectVersionAcl",
        "s3:GetObjectVersionTagging",
        "s3:GetObjectRetention",
        "s3:GetObjectLegalHold"
      ]
      resources = [
        "arn:aws:s3:::${statement.key}/*",
        "${module.s3_destination[statement.key].bucket_arn}/*"
      ]
    }
  }

  dynamic "statement" {
    for_each = module.this.enabled ? var.bucket_names : {}

    content {
      effect = "Allow"
      actions = [
        "s3:ReplicateObject",
        "s3:ReplicateDelete",
        "s3:ReplicateTags",
        "s3:ObjectOwnerOverrideToBucketOwner"
      ]
      resources = [
        "arn:aws:s3:::${statement.key}/*",
        "${module.s3_destination[statement.key].bucket_arn}/*"
      ]
    }
  }
}

##
#
# Creates buckets, IAM roles and policies to receive S3 replication.
#
###

module "label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  attributes  = [var.replica_bucket_suffix]
  label_order = ["name", "attributes"]

  context = module.this.context
}

module "s3_destination" {
  source  = "cloudposse/s3-bucket/aws"
  version = "0.43.0"

  for_each           = module.this.enabled ? var.bucket_names : {}
  name               = each.key
  acl                = each.value.acl
  versioning_enabled = var.versioning_enabled

  block_public_acls       = each.value.block_public
  block_public_policy     = each.value.block_public
  ignore_public_acls      = each.value.block_public
  restrict_public_buckets = each.value.block_public

  cors_rule_inputs = each.value.cors_rules

  lifecycle_rules = [{
    enabled = true
    prefix  = ""
    tags    = {}

    enable_glacier_transition            = false
    enable_deeparchive_transition        = false
    enable_standard_ia_transition        = false
    enable_current_object_expiration     = false
    enable_noncurrent_version_expiration = true

    abort_incomplete_multipart_upload_days         = 5
    noncurrent_version_glacier_transition_days     = 30
    noncurrent_version_deeparchive_transition_days = 60
    noncurrent_version_expiration_days             = var.noncurrent_version_expiration_days

    standard_transition_days    = 30
    glacier_transition_days     = 60
    deeparchive_transition_days = 90
    expiration_days             = 90
  }]

  providers = {
    aws = aws.replica
  }

  context = module.label.context
}

# Allow source account to replicate to destination bucket
resource "aws_s3_bucket_policy" "destination" {
  provider = aws.replica
  for_each = module.this.enabled ? var.bucket_names : {}
  bucket   = format("%s-%s", each.key, var.replica_bucket_suffix)

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "PolicyForDestinationBucket",
  "Statement": [
    {
      "Sid": "AllowReplicationOfObjects",
      "Effect": "Allow",
      "Principal": {
       "AWS": "arn:aws:iam::${var.aws_account_id}:root" 
      },
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateTags",
        "s3:ReplicateDelete",
        "s3:ObjectOwnerOverrideToBucketOwner"
      ],
      "Resource": [
        "arn:aws:s3:::${module.s3_destination[each.key].bucket_id}/*"
      ]
    },
    {
      "Sid": "AllowReplicationOfBucket",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${var.aws_account_id}:root"
      },
      "Action": [
        "s3:List*",
        "s3:Get*",
        "s3:GetBucketVersioning",
        "s3:PutBucketVersioning"
      ],
      "Resource": [
        "arn:aws:s3:::${module.s3_destination[each.key].bucket_id}"
      ]
    }
  ]
}
POLICY
}
