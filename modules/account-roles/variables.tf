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

variable "identity_account_id" {
  type        = string
  description = "The AWS account ID of the identity account. Must be provided if assume_role_names is used in the roles map"
  default     = ""
}

variable "roles" {
  type        = map(object({

    # The purpose of the role
    description = string

    # Role ARNs allowed to assume this role
    assume_role_arns = optional(list(string), [])

    # Role names in the identity account allowed to assume this role
    # Stage will be prepended to the role name
    # These roles and the ARNs above must exist before this module is applied
    assume_role_names = optional(list(string), [])

    # The assumer must have MFA enabled
    enforce_mfa = bool

    # Role ARNs attached to this role
    managed_policy_arns = list(string)

    # The maximum session duration (in seconds) for the role. Can have a value from 1 hour to 12 hours (in seconds)
    max_session_duration = number
  }))
  description = "Map of role names to role data, to be created in this account"
  default     = {}
}
