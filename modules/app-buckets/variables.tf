variable "buckets" {
  type = map(object(
    {
      acl                = string
      versioning_enabled = bool
      block_public       = bool
      bucket_name        = string
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
  description = "Map of bucket name fragment to config object. Set bucket_name to null unless overriding."
}

variable "generate_s3_backup_policy" {
  type        = bool
  default     = false
  description = "Create a policy to allow readonly access to S3 buckets for backup purposes"
}

variable "create_policy" {
  type        = bool
  default     = false
  description = "If true, creates an IAM policy & permissions to allow application-level access to each bucket. The policy ARN is output."
}

variable "use_bucket_name_only" {
  type        = bool
  default     = false
  description = "If true, creates buckets using keys in `buckets` var, else names buckets using full context."
}
