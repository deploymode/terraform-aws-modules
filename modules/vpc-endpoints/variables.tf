variable "enabled" {
  type        = bool
  description = "Set to false to prevent the module from creating any resources"
  default     = true
}

variable "aws_account_id" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "delimiter" {
  type    = string
  default = "-"
}

variable "regex_replace_chars" {
  type    = string
  default = "/[^a-zA-Z0-9]/"
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
  type    = string
  default = "network"
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
