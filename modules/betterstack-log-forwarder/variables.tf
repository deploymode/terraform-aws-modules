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

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 3
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 128
}
