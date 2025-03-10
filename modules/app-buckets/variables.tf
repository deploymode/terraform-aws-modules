variable "buckets" {
  type = map(object(
    {
      acl                = optional(string, "private")
      versioning_enabled = optional(bool, true)
      # Set block_public to false to allow setting block_public_acls, block_public_policy, ignore_public_acls, restrict_public_buckets
      block_public            = optional(bool, true)
      block_public_acls       = optional(bool, false)
      block_public_policy     = optional(bool, false)
      ignore_public_acls      = optional(bool, false)
      restrict_public_buckets = optional(bool, false)
      object_ownership        = optional(string, "BucketOwnerEnforced")
      bucket_policy           = optional(string)
      bucket_name             = optional(string)
      cors_rules = list(object({
        allowed_headers = list(string)
        allowed_methods = list(string)
        allowed_origins = list(string)
        expose_headers  = list(string)
        max_age_seconds = number
      }))
      allow_delete       = optional(bool, true)
      allowed_extensions = optional(list(string), [])
      # Paths are relative to the bucket root "/"
      allowed_public_paths = optional(list(string), [])
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
