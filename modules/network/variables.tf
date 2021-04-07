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
}

variable "nat_instance_type" {
  type    = string
  default = "t3a.micro"
}

variable "assign_elastic_ips" {
  type    = bool
  default = false
}
