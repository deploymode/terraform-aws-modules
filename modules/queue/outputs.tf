// SQS

output "queue_arn" {
  description = "The ARN of the SQS queue"
  value       = (module.this.enabled && length(var.roles_for_queue_access) > 0) ? module.queue.this_sqs_queue_arn : ""
}

output "queue_name" {
  description = "The name of the SQS queue"
  value       = (module.this.enabled && length(var.roles_for_queue_access) > 0) ? module.queue.this_sqs_queue_name : ""
}
