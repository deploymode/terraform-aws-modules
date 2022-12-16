variable "provision_account_settings" {
  type        = bool
  default     = true
  description = "Apply account settings - currently just password policy"
}

// The additional_permissions map keys must be alpha-numeric
variable "groups" {
  type = map(object({
    policy_arns = optional(list(string), [])
    manage_keys = optional(bool, false)
    # Create a role with the same permissions, minus those related to user/key/MFA management:
    # for assume-role purposes, e.g. local testing against AWS
    create_role = optional(bool, false)
    additional_permissions = optional(map(object(
      {
        permissions = list(string)
        resources   = list(string)
      }
    )), {})
  }))
  default     = {}
  description = "Map of IAM group names to policies and settings."
}

variable "users" {
  type = map(object({
    force_destroy       = bool
    groups              = list(string)
    generate_access_key = bool
  }))
  default     = {}
  description = "Map of IAM users with assigned groups and settings."
}

variable "encryption_key" {
  type        = string
  default     = null
  description = "PGP key or keybase user name for encrypting passwords and credentials. Specify keybase string as `keybase:username`."
}

// Account Settings
variable "minimum_password_length" {
  type        = number
  default     = 12
  description = "Min password length"
}

variable "allow_users_to_change_password" {
  type        = bool
  default     = true
  description = "Allow users to change passwords"
}
