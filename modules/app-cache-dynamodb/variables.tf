variable "dynamodb_cache_ttl_attribute" {
  type        = string
  default     = "expires_at"
  description = "DynamoDB table TTL attribute"
}
