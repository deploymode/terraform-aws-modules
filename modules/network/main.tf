module "vpc" {
  source     = "cloudposse/vpc/aws"
  version    = "0.21.1"
  cidr_block = var.account_network_cidr
  context    = module.this.context
}

module "subnets" {
  source               = "cloudposse/dynamic-subnets/aws"
  version              = "0.38.0"
  availability_zones   = var.zones
  vpc_id               = module.vpc.vpc_id
  igw_id               = module.vpc.igw_id
  cidr_block           = module.vpc.vpc_cidr_block
  nat_gateway_enabled  = var.enable_nat_gateway
  nat_instance_enabled = var.enable_nat_instance
  nat_instance_type    = var.nat_instance_type
  nat_elastic_ips = var.assign_elastic_ips ? [
    for az, eip in aws_eip.nat_ips : eip.public_ip
  ] : []
  context = module.this.context
}

resource "aws_eip" "nat_ips" {
  for_each = var.assign_elastic_ips ? toset(var.zones) : []
  vpc      = true

  depends_on = [
    module.vpc
  ]
}

// VPC Endpoints

// Gateway Endpoint for S3

module "s3_endpoint_label" {
  source     = "cloudposse/label/null"
  version    = "0.24.1"
  context    = module.this.context
  attributes = compact(concat(module.this.attributes, ["s3"]))
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = module.vpc.vpc_id
  service_name = format("com.amazonaws.%s.s3", var.aws_region)

  route_table_ids = module.subnets.private_route_table_ids

  tags = module.s3_endpoint_label.tags
}
