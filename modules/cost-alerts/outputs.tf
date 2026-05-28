output "anomaly_monitor_arn" {
  description = "ARN of the cost anomaly monitor."
  value       = try(aws_ce_anomaly_monitor.service[0].arn, null)
}

output "anomaly_subscription_arn" {
  description = "ARN of the cost anomaly subscription."
  value       = try(aws_ce_anomaly_subscription.email[0].arn, null)
}

output "budget_names" {
  description = "Map of budget key to AWS budget name."
  value       = { for k, b in aws_budgets_budget.daily : k => b.name }
}
