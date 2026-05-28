variable "notification_emails" {
  type        = list(string)
  description = "Email addresses to subscribe to both anomaly alerts and budget notifications. Each subscriber must independently confirm their AWS subscription."

  validation {
    condition     = length(var.notification_emails) > 0
    error_message = "At least one notification email is required."
  }
}

variable "anomaly_threshold_usd" {
  type        = number
  description = "Minimum total impact in USD for an anomaly to trigger a notification."
  default     = 5
}

variable "budgets" {
  type = map(object({
    limit_amount      = string
    linked_account_id = string
  }))
  description = <<-EOT
    Map of daily budgets to create. Key is a logical name used as a label attribute.
    limit_amount is the dollar limit (string, AWS API requires string).
    linked_account_id filters cost to a single linked account.
  EOT
  default     = {}
}
