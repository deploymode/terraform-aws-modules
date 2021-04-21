variable "roles_for_queue_access" {
  type        = list(string)
  description = "Role ARNs for use in SQS policy"
  default     = []
}
