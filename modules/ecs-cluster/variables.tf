variable "aws_account_id" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type        = string
  description = "VPC ID - must be specified if `create_service_discovery_namespace` is true"
  default     = null
}

variable "default_capacity_provider" {
  type        = string
  description = "Cluster capacity provider to use as default"
  default     = "FARGATE"
}

variable "container_insights_enabled" {
  type        = bool
  description = "Whether to enable Container Insights on the cluster"
  default     = false
}

variable "create_service_discovery_namespace" {
  type        = bool
  description = "If true, create service discovery DNS namespace"
  default     = false
}
