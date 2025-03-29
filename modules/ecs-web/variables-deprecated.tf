// Buckets

variable "external_app_buckets" {
  type        = list(string)
  description = "Existing S3 buckets used by the application. Allows application and CodePipeline roles to access these buckets."
  default     = []
  validation {
    condition     = length(var.external_app_buckets) == 0
    error_message = "This variable has been deprecated. Manage S3 access using `ecs_task_policy_arns` and `codebuild_policy_arns`"
  }
}