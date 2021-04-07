variable "region" {
  type        = string
  description = "AWS Region"
}

variable "zone_config" {
  description = "Zone config"
  type = list(object({
    subdomain    = string
    zone_name    = string
    name_servers = list(string)
  }))
}

variable "primary_role_arn" {
  type        = string
  default     = null
  description = "IAM Role ARN to use for primary account (which has the main DNS zone)"
}

variable "delegated_role_arn" {
  type        = string
  default     = null
  description = "IAM Role ARN to use for delegated account (which has the delegated DNS zone)"
}
