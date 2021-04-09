variable "aws_region" {
  type = string
}

// Network

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs"
}

variable "vpc_endpoint_ecr_security_group_ids" {
  type        = list(string)
  description = "Security groups which control access to VPC endpoint for ECR"
  default     = []
}

variable "vpc_endpoint_logs_security_group_ids" {
  type        = list(string)
  description = "Security groups which control access to VPC endpoint for CloudWatch Logs"
  default     = []
}

variable "vpc_endpoint_ssm_security_group_ids" {
  type        = list(string)
  description = "Security groups which control access to VPC endpoint for SSM"
  default     = []
}

# https://docs.aws.amazon.com/vpc/latest/userguide/vpce-interface.html#access-service-though-endpoint
variable "enable_private_dns" {
  type        = bool
  description = "Enable private DNS for Interface endpoints. Allows accessing the services using their normal DNS names."
  default     = true
}
