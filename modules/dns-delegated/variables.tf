variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "primary_role_arn" {
  type        = string
  description = "AWS role ARN of primary account"
}

variable "delegated_aws_account_id" {
  type        = string
  description = "AWS Account ID of target (delegated) account"
}

variable "delegated_role_name" {
  type        = string
  description = "Role name in target account to use for setting up delegated DNS zone"
  default     = "OrganizationAccountAccessRole"
}

variable "zone_config" {
  description = "Zone config - a list of objects with subdomain, zone_name and dnssec_enabled keys"
  type = list(object({
    subdomain = string
    zone_name = string
    dnssec_enabled    = optional(bool, false)
  }))
}
