
variable "roles_for_queue_access" {
  type        = list(string)
  description = "Role ARNs for use in SQS policy"
  default     = []
}

variable "queues" {
  description = "Queues to create with settings"
  type = map(object({
    enabled    = optional(bool, true)
    name       = optional(string, null)
    fifo_queue = optional(bool, false)
    # Specifies whether message deduplication occurs at the message group or queue level. Valid values are messageGroup and queue.
    deduplication_scope         = optional(string, "queue")
    content_based_deduplication = optional(bool, false)
    # The visibility timeout for the queue. An integer from 0 to 43200 (12 hours)
    visibility_timeout_seconds = optional(number, 30)
    message_retention_seconds  = optional(number, 345600)
  }))
  default = {}
}
