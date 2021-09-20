module "s3_bucket" {
  source  = "cloudposse/s3-bucket/aws"
  version = "0.43.0"

  for_each = var.buckets

  name = join("-", [module.this.id, each.key])

  acl                     = each.value.acl
  block_public_acls       = each.value.block_public
  block_public_policy     = each.value.block_public
  ignore_public_acls      = each.value.block_public
  restrict_public_buckets = each.value.block_public

  versioning_enabled = each.value.versioning_enabled

  cors_rule_inputs = each.value.cors_rules

  context = module.this.context
}
