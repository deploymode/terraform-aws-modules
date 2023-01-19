// SQS

output "queue_arn" {
  description = "The ARN of the SQS queues"
  value       = module.this.enabled ? { for queue, queue_info in module.queue : queue => queue_info.queue_arn } : {}
}

output "queue_name" {
  description = "The name of the SQS queue"
  value       = module.this.enabled ? { for queue, queue_info in module.queue : queue => queue_info.queue_name } : {}
}

output "queue_access_policy_arn" {
  description = "Policy to allow access to queue"
  value       = module.this.enabled ? { for queue, queue_info in aws_iam_policy.sqs_policy : queue => queue_info.arn } : {}
}

data "aws_region" "current" {}

output "queue_region" {
  description = "SQS region"
  value       = data.aws_region.current.name
}
