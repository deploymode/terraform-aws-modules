output "table_name" {
  value       = module.dynamodb.table_name
  description = "DynamoDB table name for app cache"
}

output "table_arn" {
  value       = module.dynamodb.table_arn
  description = "DynamoDB table ARN"
}

output "access_policy_arn" {
  value       = var.create_access_policy ? join("", aws_iam_policy.dynamodb_access_policy.*.arn) : ""
  description = "Policy to allow access to DynamoDB table for app cache"
}

output "access_policy_document" {
  value       = data.aws_iam_policy_document.dynamodb.json
  description = "JSON policy document to allow access to DynamoDB table for app cache"
}
