output "replica_bucket_arns" {
  value = tomap({
    for k, bucket in module.s3_destination : k => bucket.bucket_arn
  })
  description = "ARNs of DR buckets"
}

output "source_replication_policy" {
  value       = aws_iam_role_policy.s3_replication[*].id
  description = "ARN of replication policy"
}

output "source_replication_role_arn" {
  value       = aws_iam_role.replication.*.arn
  description = "ARN of replication role"
}

output "enabled" {
  value       = module.this.enabled
  description = "Is module enabled"
}
