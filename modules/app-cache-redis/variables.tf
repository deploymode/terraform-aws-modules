// Networking
variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "availability_zones" {
  type        = list(string)
  description = "Availability zone IDs - relevant when multi-AZ is enabled"
  default     = []
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

// Redis infra

variable "cluster_mode_enabled" {
  type        = bool
  description = "Flag to enable/disable creation of a native redis cluster. `automatic_failover_enabled` must be set to `true`. Only 1 `cluster_mode` block is allowed"
  default     = false
}

variable "cluster_size" {
  type        = number
  default     = 1
  description = "Number of nodes in cluster. *Ignored when `cluster_mode_enabled` == `true`*"
}

# https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/CacheNodes.SupportedTypes.html
variable "instance_type" {
  type        = string
  default     = "cache.t4g.micro"
  description = "Elastic cache instance type"
}

// Redis settings

variable "family" {
  type        = string
  default     = "redis6.x"
  description = "Redis family"
}

variable "engine_version" {
  type        = string
  default     = "6.2"
  description = "Redis engine version"
}

variable "password" {
  type        = string
  description = "Auth token for password protecting redis, `transit_encryption_enabled` must be set to `true`. Password must be longer than 16 chars"
  default     = null

}
