variable "aws_account_id" {
  type = string
}

variable "aws_region" {
  type = string
}

// Network

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs"
}


// ALB

variable "access_logs_enabled" {
  type        = bool
  description = "Enable ALB access logs"
  default     = false
}

variable "alb_security_group_ids" {
  type        = list(string)
  description = "Additional Security Group IDs to allow access to ALB"
  default     = []
}

variable "target_group_port" {
  type        = number
  default     = 80
  description = "The port for target group traffic"
}

variable "http_port" {
  type        = number
  default     = 80
  description = "The port for the HTTP listener"
}

variable "http_enabled" {
  type        = bool
  default     = true
  description = "A boolean flag to enable/disable HTTP listener"
}

variable "certificate_arn" {
  type        = string
  default     = ""
  description = "The ARN of the default SSL certificate for HTTPS listener"
}

variable "https_port" {
  type        = number
  default     = 443
  description = "The port for the HTTPS listener"
}

variable "https_enabled" {
  type        = bool
  default     = false
  description = "A boolean flag to enable/disable HTTPS listener"
}

variable "http_to_https_redirect" {
  type        = bool
  default     = false
  description = "Whether to redirect HTTP to HTTPS"
}

variable "allowed_ipv4_cidr_blocks" {
  type        = list
  default     = ["0.0.0.0/0"]
  description = "IPv4 ranges allowed to access the load balancer"
}

variable "allowed_ipv6_cidr_blocks" {
  type        = list
  default     = ["::/0"]
  description = "IPv6 ranges allowed to access the load balancer"
}

// Health Checks

variable "health_check_path" {
  type        = string
  default     = "/"
  description = "The destination for the health check request"
}

variable "health_check_timeout" {
  type        = number
  default     = 10
  description = "The amount of time to wait in seconds before failing a health check request"
}

variable "health_check_healthy_threshold" {
  type        = number
  default     = 2
  description = "The number of consecutive health checks successes required before considering an unhealthy target healthy"
}

variable "health_check_unhealthy_threshold" {
  type        = number
  default     = 2
  description = "The number of consecutive health check failures required before considering the target unhealthy"
}

variable "health_check_interval" {
  type        = number
  default     = 15
  description = "The duration in seconds in between health checks"
}

variable "health_check_matcher" {
  type        = string
  default     = "200-399"
  description = "The HTTP response codes to indicate a healthy check"
}

// Timeouts

variable "deregistration_delay" {
  type        = number
  default     = 15
  description = "The amount of time to wait in seconds before changing the state of a deregistering target to unused"
}

variable "idle_timeout" {
  type        = number
  default     = 60
  description = "The time in seconds that the connection is allowed to be idle"
}

// DNS alias and Failover site

variable "cf_certificate_arn" {
  type        = string
  description = "Certificate from us-east-1, required for CloudFront"
  default     = ""
}

// DNS
variable "hosted_zone_id" {
  type        = string
  description = "Main route 53 hosted zone ID"
  default     = ""
}

variable "hosted_zone_name" {
  type        = string
  description = "Main route 53 hosted zone name"
  default     = ""
}

variable "dns_prefix" {
  type        = string
  description = "Subdomain of the load balancer's domain. Defaults to `var.stage`"
  default     = ""
}

variable "html_source_path" {
  type        = string
  description = "Directory containing HTML files to upload to S3"
}

variable "index_document" {
  type        = string
  description = "Amazon S3 returns this index document when requests are made to the root domain or any of the subfolders"
  default     = "index.html"
}

variable "error_document" {
  type        = string
  description = "An absolute path to the document to return in case of a 4XX error"
  default     = ""
}

variable "aliases" {
  type        = list(string)
  description = "S3 website aliases for CloudFront"
  default     = []
}

variable "remove_objects_on_destroy" {
  type        = bool
  description = "Delete all objects from the bucket so that the bucket can be destroyed without error (e.g. true or false)"
}
