variable "log_groups" {
  type = map(object(
    {
      log_group_name = string
      retention_days = number
    }
  ))
  description = "Map of objects containing log group name and retention days"
  default     = {}
}
