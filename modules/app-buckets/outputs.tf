output "bucket_arns" {
  value = tomap({
    for k, bucket in module.s3_bucket : k => bucket.bucket_arn
  })
  description = "ARNs of created buckets"
}
