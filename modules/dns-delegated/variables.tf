variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "delegated_aws_account_id" {
  type        = string
  description = "AWS Account ID of target (delegated) account"
}

variable "zone_config" {
  description = "Zone config"
  type = list(object({
    subdomain = string
    zone_name = string
  }))
}

variable "delegated_role_name" {
  type        = string
  description = "Role name in target account to use for setting up delegated DNS zone"
  default     = "OrganizationAccountAccessRole"
}
