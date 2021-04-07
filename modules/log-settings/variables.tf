variable "enabled" {
  type        = bool
  description = "Set to false to prevent the module from creating any resources"
  default     = true
}

variable "delimiter" {
  type    = string
  default = "-"
}

variable "regex_replace_chars" {
  type    = string
  default = "/[^a-zA-Z0-9-._]/"
}

variable "attributes" {
  type        = list(string)
  description = "Additional attributes (_e.g._ \"1\")"
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Additional tags (_e.g._ { BusinessUnit : ABC })"
  default     = {}
}

variable "namespace" {
  type = string
}

variable "stage" {
  type = string
}

variable "app" {
  type        = string
  description = "Component name"
}

variable "ecs_log_group_retention_days" {
  type        = number
  description = "Retention period for ECS log groups"
  default     = 14
}

variable "codebuild_log_group_retention_days" {
  type        = number
  description = "Retention period for CodeBuild log groups"
  default     = 14
}

variable "ecs_log_groups" {
  type        = map
  description = "All ECS log groups"
  default     = {}
}

variable "log_groups_to_process" {
  type        = list(string)
  description = "Log groups to apply retention policy to"
  default     = []
}
