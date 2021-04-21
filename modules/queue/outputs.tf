// SQS

output "queue_arn" {
  description = "The ARN of the SQS queue"
  value       = var.provision_sqs ? module.queue.this_sqs_queue_arn : ""
}

output "queue_name" {
  description = "The name of the SQS queue"
  value       = var.provision_sqs ? module.queue.this_sqs_queue_name : ""
}
