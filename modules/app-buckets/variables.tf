variable "buckets" {
  type = list(object(
    {
      name               = string
      acl                = string
      versioning_enabled = bool
      allow_public       = bool
    }
  ))
  default     = []
  description = "List of buckets to create with their config"
}
