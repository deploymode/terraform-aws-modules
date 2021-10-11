variable "accounts" {
  type = map(object({
    account_id           = string
    org_access_role_name = string
  }))
  description = "Map of account names to account IDs in the Org, e.g. master, prod"
}

variable "groups" {
  type        = list(string)
  default     = []
  description = "List of IAM groups to create in account"
}

variable "users" {
  type = map(object({
    force_destroy = bool
    groups        = list(string)
  }))
  default     = {}
  description = "List of IAM users with assigned groups to create in account"
}

variable "keybase_user" {
  type        = string
  default     = ""
  description = "Keybase username for encrypting IAM user passwords"
}
