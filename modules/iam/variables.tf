variable "accounts" {
  type = map(object({
    account_id           = string
    org_access_role_name = string
  }))
  description = "Map of account names to account IDs in the Org, e.g. master, prod"
}

// TODO
# variable "account_settings" {
#   type = map(object({
#     max_session_duration = number
#   }))
#   description = "Map of account names to account-specific settings"
#   default     = {}
# }

variable "groups" {
  type        = list(string)
  default     = []
  description = "List of IAM groups to create in account"
}

variable "users" {
  type = map(object({
    force_destroy       = bool
    groups              = list(string)
    generate_access_key = bool
  }))
  default     = {}
  description = "List of IAM users with assigned groups to create in account"
}

variable "keybase_user" {
  type        = string
  default     = ""
  description = "Keybase username for encrypting IAM user passwords"
}

variable "provision_master_admin_role" {
  type        = bool
  default     = true
  description = "Create an admin role for the master account"
}

variable "master_account_name" {
  type        = string
  default     = "master"
  description = "Name of master account"
}
