output "sns_topic_arn" {
  description = "ARN of the alarm notification SNS topic."
  value       = try(aws_sns_topic.alarms[0].arn, null)
}
