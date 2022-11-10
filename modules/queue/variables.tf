variable "roles_for_queue_access" {
  type        = list(string)
  description = "Role ARNs for use in SQS policy"
  default     = []
}

variable "visibility_timeout_seconds" {
  description = "The visibility timeout for the queue. An integer from 0 to 43200 (12 hours)"
  type        = number
  default     = 30
}
