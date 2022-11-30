variable "users" {
  type = map(object({
    force_destroy          = optional(bool, true)
    generate_access_key    = optional(bool, true)
    managed_policy_arn_map = optional(map(string), {})
    inline_policy_map = optional(map(object({
      actions   = list(string)
      resources = list(string)
    })), {})
    ssm_base_path = optional(string, null)
  }))
  default     = {}
  description = "List of IAM users to create in account"
}
