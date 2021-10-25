variable "buckets" {
  type = map(object(
    {
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
  default     = {}
  description = "Map of bucket name fragment to config object"
}

variable "generate_s3_backup_policy" {
  type        = bool
  default     = false
  description = "Create a policy to allow readonly access to S3 buckets for backup purposes"
}
