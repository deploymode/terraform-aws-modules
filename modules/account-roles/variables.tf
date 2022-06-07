variable "dns_assume_role_arns" {
  type        = list(string)
  description = "Role/user ARN(s) which may assume the DNS role"
  default     = []
}

variable "provision_dns_role" {
  type        = bool
  description = "If true, create a role that can manage DNS in this account"
  default     = false
}

variable "admin_assume_role_arns" {
  type        = list(string)
  description = "Role/user ARN(s) which may assume the Admin role"
  default     = []
}

variable "provision_admin_role" {
  type        = bool
  description = "If true, create a role that can perform Admin functions in this account"
  default     = false
}

variable "admin_session_duration" {
  type        = number
  description = "The maximum session duration (in seconds) for the role. Can have a value from 1 hour to 12 hours"
  default     = 3600
}
