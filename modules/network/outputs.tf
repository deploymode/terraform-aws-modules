output "public_elastic_ips" {
  value       = var.assign_elastic_ips ? aws_eip.nat_ips.* : []
  description = "Elastic IPs allocated to public subnet"
}

output "nat_ips" {
  description = "IP Addresses in use for NAT"
  value       = module.subnets.nat_ips
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways created"
  value       = module.subnets.nat_gateway_ids
}

output "nat_gateway_public_ips" {
  description = "EIP of the NAT Gateway"
  value       = module.subnets.nat_gateway_public_ips
}

output "nat_instance_ids" {
  description = "IDs of the NAT Instances created"
  value       = module.subnets.nat_instance_ids
}

output "public_subnet_cidrs" {
  value       = module.subnets.public_subnet_cidrs
  description = "Public subnet CIDRs"
}

output "private_subnet_cidrs" {
  value       = module.subnets.private_subnet_cidrs
  description = "Private subnet CIDRs"
}

output "private_subnet_ids" {
  value       = module.subnets.private_subnet_ids
  description = "Private subnet IDs"
}

output "public_subnet_ids" {
  value       = module.subnets.public_subnet_ids
  description = "Public subnet IDs"
}

output "vpc_cidr" {
  value       = module.vpc.vpc_cidr_block
  description = "VPC CIDR block"
}

output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC ID"
}

output "default_security_group_id" {
  value       = module.vpc.vpc_default_security_group_id
  description = "The ID of the security group created by default on VPC creation"
}

output "vpc_main_route_table_id" {
  value       = module.vpc.vpc_main_route_table_id
  description = "The ID of the main route table associated with this VPC"
}

output "vpc_default_network_acl_id" {
  value       = module.vpc.vpc_default_network_acl_id
  description = "The ID of the network ACL created by default on VPC creation"
}

output "vpc_default_security_group_id" {
  value       = module.vpc.vpc_default_security_group_id
  description = "The ID of the security group created by default on VPC creation"
}

output "vpc_default_route_table_id" {
  value       = module.vpc.vpc_default_route_table_id
  description = "The ID of the route table created by default on VPC creation"
}

output "vpc_private_route_table_ids" {
  value       = module.subnets.private_route_table_ids
  description = "The IDs of the route table associated with the private subnets"
}

output "vpc_public_route_table_ids" {
  value       = module.subnets.public_route_table_ids
  description = "The IDs of the route table associated with the public subnets"
}
