output "policy_arns" {
  value = { for name, policy in module.iam_policy : name => policy.policy_arn }
}
