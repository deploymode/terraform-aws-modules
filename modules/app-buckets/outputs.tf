output "bucket_names" {
  value = tomap({
    for k, bucket in module.s3_bucket : k => bucket.bucket_id
  })
  description = "Names of created buckets"
}

output "bucket_arns" {
  value = tomap({
    for k, bucket in module.s3_bucket : k => bucket.bucket_arn
  })
  description = "ARNs of created buckets"
}

output "s3_backup_policy_arn" {
  value       = var.generate_s3_backup_policy ? join("", aws_iam_policy.s3_backup_policy.*.arn) : ""
  description = "Policy to allow readonly access to backup buckets"
}
