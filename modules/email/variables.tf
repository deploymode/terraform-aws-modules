variable "aws_account_id" {
  description = "Current AWS account ID."
  type        = string
}

variable "domain" {
  description = "The domain to create the SES identity for."
  type        = string
}

variable "zone_id" {
  type        = string
  description = "Route53 parent zone ID. If provided (not empty), the module will create Route53 DNS records used for verification"
  default     = ""
}

variable "verify_domain" {
  type        = bool
  description = "If provided the module will create Route53 DNS records used for domain verification."
  default     = false
}

variable "verify_dkim" {
  type        = bool
  description = "If provided the module will create Route53 DNS records used for DKIM verification."
  default     = false
}

variable "create_iam_role" {
  type        = bool
  description = "Creates an IAM role with permission to send emails from SES domain. Probably not required if `ses_user_enabled` is true."
  default     = false
}

variable "ses_user_enabled" {
  type        = bool
  description = "Creates user with permission to send emails from SES domain"
  default     = false
}

variable "iam_key_id_ssm_param_path" {
  type        = string
  default     = ""
  description = "SSM param store path for IAM key ID"
}

variable "iam_key_secret_ssm_param_path" {
  type        = string
  default     = ""
  description = "SSM param store path for IAM key secret"
}

variable "iam_access_key_max_age" {
  type        = number
  description = "Maximum age of IAM access key (seconds). Defaults to 0 (no expiry). Set to 0 to disable expiration."
  default     = 0

  validation {
    condition     = var.iam_access_key_max_age >= 0
    error_message = "The iam_access_key_max_age must be 0 (disabled) or greater."
  }
}
