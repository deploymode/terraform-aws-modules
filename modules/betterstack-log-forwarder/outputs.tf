output "log_group_names" {
  value       = var.log_group_names
  description = "Names of the CloudWatch log groups"
}

output "lambda_function_arn" {
  description = "ARN of the created Lambda function"
  value       = module.log_forwarder.lambda_function_arn
}