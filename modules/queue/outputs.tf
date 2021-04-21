// SQS

output "queue_arn" {
  description = "The ARN of the SQS queue"
  value       = module.this.enabled ? module.queue.this_sqs_queue_arn : ""
}

output "queue_name" {
  description = "The name of the SQS queue"
  value       = module.this.enabled ? module.queue.this_sqs_queue_name : ""
}

output "queue_access_policy_arn" {
  description = "Policy to allow access to queue"
  value       = join("", aws_iam_policy.sqs_policy.*.arn)
}
