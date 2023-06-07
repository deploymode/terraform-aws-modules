variable "aws_account_id" {
  description = "Third-party AWS account ID"
  type        = string
}

variable "external_id" {
  description = "External ID required for assume role. Set to null if not required."
  type        = string
  default     = null
}

variable "aws_managed_policy_names" {
  description = "Built-in policy names to attach to role"
  type        = list(string)
  default     = []
}

variable "policy_arns" {
  description = "Custom policy ARNs to attach to role"
  type        = list(string)
  default     = []
}

variable "iam_permissions" {
  description = "IAM permissions to attach to role"
  type        = list(string)
  default     = []
}
