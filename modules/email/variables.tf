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

variable "create_spf_record" {
  type        = bool
  description = "If provided the module will create an SPF record for `domain`."
  default     = false
}

variable "custom_from_subdomain" {
  type        = list(string)
  description = "If provided the module will create a custom subdomain for the `From` address."
  default     = []
  nullable    = false

  validation {
    condition     = length(var.custom_from_subdomain) <= 1
    error_message = "Only one custom_from_subdomain is allowed."
  }

  validation {
    condition     = length(var.custom_from_subdomain) > 0 ? can(regex("^[a-zA-Z0-9-]+$", var.custom_from_subdomain[0])) : true
    error_message = "The custom_from_subdomain must be a valid subdomain."
  }
}

variable "custom_from_behavior_on_mx_failure" {
  type        = string
  description = "The behaviour of the custom_from_subdomain when the MX record is not found. Defaults to `UseDefaultValue`. Ignored if `custom_from_subdomain` is empty."
  default     = "UseDefaultValue"

  validation {
    condition     = contains(["UseDefaultValue", "RejectMessage"], var.custom_from_behavior_on_mx_failure)
    error_message = "The custom_from_behavior_on_mx_failure must be `UseDefaultValue` or `RejectMessage`."
  }
}

variable "dmarc_record" {
  type        = list(string)
  description = "The DMARC record to create for the domain. If null, a default DMARC record will be created. Set to an empty list to disable DMARC."
  default     = ["v=DMARC1; p=none;"]
}

# Permissions

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

# SNS notifications

variable "notification_emails" {
  type        = map(string)
  description = "A map of SES event to email address to notify. Keys are `bounce`, `complaint`, and `delivery`."
  default     = {}

  validation {
    condition = length(setunion(keys(var.notification_emails), ["bounce", "complaint", "delivery"])) == 3
    error_message = "Only `bounce`, `complaint`, and `delivery` are allowed keys in notification_emails."
  }
}
