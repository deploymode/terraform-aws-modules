variable "account_email" {
  type        = string
  description = "Account email format string. Used in combination with `name`, e.g. ops-%s@deploymode.com"
}

variable "account_role_name" {
  type        = string
  description = "IAM role that Organization automatically preconfigures in the new member account"
  default     = "OrganizationAccountAccessRole"
}
