module "s3_bucket" {
  source  = "cloudposse/s3-bucket/aws"
  version = "0.41.0"

  for_each = var.buckets

  name                    = each.value.name
  acl                     = each.value.acl
  versioning_enabled      = each.value.versioning_enabled
  block_public_acls       = ! each.value.allow_public
  block_public_policy     = ! each.value.allow_public
  ignore_public_acls      = ! each.value.allow_public
  restrict_public_buckets = ! each.value.allow_public

  context = module.this.context
}
