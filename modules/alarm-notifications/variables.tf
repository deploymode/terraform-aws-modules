variable "betterstack_enabled" {
  type        = bool
  description = "Create a Betterstack AWS CloudWatch integration via the better-uptime provider and subscribe its webhook to the topic. Requires BETTERUPTIME_API_TOKEN in the environment."
  default     = false
}

variable "betterstack_policy_id" {
  type        = string
  description = "Betterstack escalation policy id for the integration"
  default     = null
}

variable "betterstack_recovery_period" {
  type        = number
  description = "Seconds an alert must stay OK before Betterstack auto-resolves the incident"
  default     = 0
}

variable "webhook_url_ssm_param" {
  type        = string
  description = "SSM parameter name holding an externally created webhook URL to subscribe to the topic. Ignored when betterstack_enabled; empty to skip."
  default     = ""
}

variable "notification_emails" {
  type        = list(string)
  description = "Email addresses to subscribe to the topic"
  default     = []
}
