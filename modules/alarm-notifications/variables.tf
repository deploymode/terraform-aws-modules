variable "webhook_url_ssm_param" {
  type        = string
  description = "SSM parameter name holding an externally created webhook URL to subscribe to the topic. Empty to skip."
  default     = ""
}

variable "notification_emails" {
  type        = list(string)
  description = "Email addresses to subscribe to the topic"
  default     = []
}
