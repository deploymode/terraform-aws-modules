variable "buckets" {
  type = map(object(
    {
      name               = string
      acl                = string
      versioning_enabled = bool
      block_public       = bool
      cors_rules = list(object({
        allowed_headers = list(string)
        allowed_methods = list(string)
        allowed_origins = list(string)
        expose_headers  = list(string)
        max_age_seconds = number
      }))
    }
  ))
  default     = []
  description = "List of buckets to create with their config"
}
