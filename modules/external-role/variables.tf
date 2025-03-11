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

variable "policy_documents" {
  description = "Custom policy documents to attach to role"
  type = map(list(object({
    policy_id = optional(string, null)
    version   = optional(string, null)
    statements = list(object({
      sid           = optional(string, null)
      effect        = optional(string, null)
      actions       = optional(list(string), null)
      not_actions   = optional(list(string), null)
      resources     = optional(list(string), null)
      not_resources = optional(list(string), null)
      conditions = optional(list(object({
        test     = string
        variable = string
        values   = list(string)
      })), [])
      principals = optional(list(object({
        type        = string
        identifiers = list(string)
      })), [])
      not_principals = optional(list(object({
        type        = string
        identifiers = list(string)
      })), [])
    }))
  })))
  default = {}
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
