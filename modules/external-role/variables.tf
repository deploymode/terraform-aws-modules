variable "aws_account_id" {
  description = "Third-party AWS account ID"
  type        = string
}

variable "external_id" {
  description = "External ID required for assume role. Set to null if not required."
  type        = string
  default     = null
}

variable "aws_policy_names" {
  description = "Built-in policies to attach to role"
  type        = list(string)
}
