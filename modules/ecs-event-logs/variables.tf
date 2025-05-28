variable "ecs_event_logs" {
  type        = map(object({
    enabled          = bool
    detail_type = string
    detail = map(list(string))
    retention_in_days = optional(number, 30)
  }))
  description = "Enable logging of stopped tasks to CloudWatch Logs. This will create a CloudWatch Log Group for stopped task events."
  default     = {}

  # Example:
  #   ecs-stopped-tasks = {
  #     enabled          = true
  #     detail_type = "ECS Task State Change"
  #     detail = {
  #       "desiredStatus" = "STOPPED"
  #       "lastStatus"    = "STOPPED"
  #     }
  #     retention_in_days = 30
  #   }
  # 
}