// Networking
variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "availability_zones" {
  type        = list(string)
  default     = []
  description = "List of Availability Zones for the cluster. If az_mode is single-az, the first value will be used."
}

variable "allowed_security_groups" {
  type        = list(string)
  default     = []
  description = "List of Security Group IDs that are allowed ingress to the cluster's Security Group created in the module"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of (private) subnet IDs"
}

// DNS

variable "zone_id" {
  type        = string
  description = "Main Route 53 hosted zone ID."
  default     = ""
}

variable "dns_subdomain" {
  type        = string
  default     = ""
  description = "The subdomain to use for the CNAME record. If not provided then the CNAME record will use var.name."
}

// memcached infra

variable "cluster_size" {
  type        = number
  default     = 1
  description = "Number of nodes in cluster. Must be > 1 and == number of AZ's when az_mode is cross-az."
}

variable "az_mode" {
  type        = string
  default     = "single-az"
  description = "Enable or disable multiple AZs, eg: single-az or cross-az"

  validation {
    condition     = var.az_mode == "single-az" || var.az_mode == "cross-az"
    error_message = "az_mode value must be either single-az or cross-az"
  }
}

# https://docs.aws.amazon.com/AmazonElastiCache/latest/mem-ug/CacheNodes.SupportedTypes.html
variable "instance_type" {
  type        = string
  default     = "cache.t4g.micro"
  description = "Elasticache instance type"
}

// memcached settings

variable "engine_version" {
  type        = string
  default     = "1.6.22"
  description = "memcached engine version"
}

variable "elasticache_parameter_group_family" {
  type        = string
  description = "ElastiCache parameter group family"
  default     = "memcached1.6"
}

variable "max_item_size" {
  type        = number
  default     = 10485760
  description = "Max item size"
}

variable "maintenance_window" {
  type        = string
  default     = "sun:13:00-sun:14:00"
  description = "Maintenance window"
}

variable "transit_encryption_enabled" {
  type        = bool
  description = "Boolean flag to enable transit encryption (requires Memcached version 1.6.12+)"
  default     = true
}