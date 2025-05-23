variable "log_group_names" {
  description = "Map of short names to Cloudwatch log group names to subscribe to"
  type        = map(string)
  default     = {}
}

variable "better_stack_token" {
  description = "BetterStack token"
  type        = string
}

variable "better_stack_ingest_host" {
  description = "BetterStack ingest host"
  type        = string
}