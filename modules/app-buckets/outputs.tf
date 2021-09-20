output "dr_bucket_arns" {
  value = tomap({
    for k, bucket in module.s3_bucket : k => bucket.bucket_arn
  })
  description = "ARNs of DR buckets"
}
