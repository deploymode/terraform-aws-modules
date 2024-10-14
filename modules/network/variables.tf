variable "aws_region" {
  type = string
}

variable "zones" {
  type = list
}

variable "account_network_cidr" {
  type        = string
  description = "VPC CIDR block"
}

variable "enable_nat_gateway" {
  type    = bool
  default = false
}

variable "enable_nat_instance" {
  type    = bool
  default = false
  description = "Enabled the NAT instance created by the Cloud Posse subnets module. Treated as `false` if `use_fck_nat_instance_image` is `true`."
}

variable "nat_instance_type" {
  type    = string
  default = "t3a.micro"
}

variable "use_fck_nat_instance_image" {
  type    = bool
  default = false
  description = <<EOT
    Use the FCK NAT instance image instead of the Cloud Posse NAT instance.
    
    Note: This effectively overrides the `enable_nat_instance` variable.
    Note: This method does not currently support allocation of Elastic IPs, which means it is not suitable if you need to whitelist the NAT instance IP addresses in external services.
    This can be handled by using the `eip_allocation_ids` variable in the FCK NAT module (which is not currently exposed in this module).
EOT
}

variable "use_fck_nat_instance_ha_mode" {
  type = bool
  default = false
  description = <<EOT
    Use the FCK NAT instance image in HA mode. This will create an ASG with a minimum of 2 instances.
EOT
}

variable "assign_elastic_ips" {
  type    = bool
  default = false
}

variable "enable_s3_endpoint" {
  type        = bool
  default     = false
  description = "If true, create S3 VPC endpoint"
}
