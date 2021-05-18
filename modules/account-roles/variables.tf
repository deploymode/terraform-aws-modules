variable "dns_role_arn" {
  type        = string
  description = "Role ARN which may assume the DNS role"
  default     = null
}

variable "provision_dns_role" {
  type        = bool
  description = "If true, create a role that can manage DNS in this account"
  default     = false
}
