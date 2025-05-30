variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs"
}

variable "security_groups" {
  type        = list(string)
  description = "Additional Security Group IDs to apply to EC2 instance"
  default     = []
}

variable "zone_id" {
  type        = string
  default     = ""
  description = "Route53 DNS Zone ID"
}

variable "instance_type" {
  type        = string
  default     = "t4g.nano"
  description = "Bastion instance type"
}

variable "ami_filter" {
  type        = map(list(string))
  default     = { "name" : ["al2023-ami-minimal-*arm64"] }
  description = "AMI filter to use for provisioning EC2 Bastion Host"
}

variable "user_data" {
  type        = list(string)
  default     = []
  description = "User data content"
}

variable "user_data_template" {
  type        = string
  default     = "user_data/amazon-linux.sh"
  description = "User Data template to use for provisioning EC2 Bastion Host"
}

variable "ssh_key_path" {
  type        = string
  description = "Save location for ssh public keys generated by the module"
}

variable "generate_ssh_key" {
  type        = bool
  description = "Whether or not to generate an SSH key"
}

variable "root_block_device_encrypted" {
  type        = bool
  default     = false
  description = "Whether to encrypt the root block device"
}

variable "root_block_device_volume_size" {
  type        = number
  default     = 8
  description = "The volume size (in GiB) to provision for the root block device. It cannot be smaller than the AMI it refers to."
}

variable "metadata_http_endpoint_enabled" {
  type        = bool
  default     = true
  description = "Whether the metadata service is available"
}

variable "metadata_http_put_response_hop_limit" {
  type        = number
  default     = 1
  description = "The desired HTTP PUT response hop limit (between 1 and 64) for instance metadata requests."
}

variable "metadata_http_tokens_required" {
  type        = bool
  default     = false
  description = "Whether or not the metadata service requires session tokens, also referred to as Instance Metadata Service Version 2."
}

variable "associate_public_ip_address" {
  type        = bool
  default     = true
  description = "Whether to associate public IP to the instance."
}

variable "assign_eip_address" {
  type        = bool
  description = "Assign an Elastic IP address to the instance"
  default     = true
}
