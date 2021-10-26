variable "aws_account_id" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs - public or private. When choosing public you can also specific that a public IP is assigned."
}

variable "s3_bucket_names" {
  type        = list(string)
  description = "Names of S3 buckets to back up - used by the ECS service"
}

variable "s3_backup_access_role_arn" {
  type        = string
  description = "Role in DR account which allows access to the S3 backup bucket - used by the ECS service"
}

variable "container_command" {
  type        = list(string)
  description = "Git branch monitored by CodePipeline"
  default     = ["azcopy"]
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule#schedule_expression
variable "backup_schedule" {
  type        = string
  description = "AWS EventBridge schedule expression"
}
