variable "dynamodb_cache_ttl_attribute" {
  type        = string
  default     = "expires_at"
  description = "DynamoDB table TTL attribute"
}

variable "create_access_policy" {
  type        = bool
  default     = true
  description = "Whether to create the IAM access policy for the DynamoDB table"
}
