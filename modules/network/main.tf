module "vpc" {
  source                  = "cloudposse/vpc/aws"
  version                 = "2.1.1"
  ipv4_primary_cidr_block = var.account_network_cidr
  context                 = module.this.context
}

module "subnets" {
  source               = "cloudposse/dynamic-subnets/aws"
  version              = "2.4.2"
  availability_zones   = var.zones
  vpc_id               = module.vpc.vpc_id
  igw_id               = [module.vpc.igw_id]
  ipv4_cidr_block      = [module.vpc.vpc_cidr_block]
  nat_gateway_enabled  = var.enable_nat_gateway
  nat_instance_enabled = var.enable_nat_instance && !var.use_fck_nat_instance_image
  nat_instance_type    = var.nat_instance_type
  nat_elastic_ips = var.assign_elastic_ips ? [
    for az, eip in aws_eip.nat_ips : eip.public_ip
  ] : []
  context = module.this.context
}

module "nat-image-label" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  attributes = compact(concat(module.this.attributes, ["nat"]))
  enabled    = true
  context    = module.this.context
}

# Create a NAT instance per AZ
module "fck-nat" {
  source  = "RaJiska/fck-nat/aws"
  version = "1.3.0"

  for_each = var.use_fck_nat_instance_image ? module.subnets.az_public_subnets_map : {}

  name                 = join("-", [module.nat-image-label.id, each.key])
  vpc_id               = module.vpc.vpc_id
  # Assumes one subnet per az
  subnet_id            = one(each.value)
  # This is not the default VPC security group, but the one created by the FCK module
  use_default_security_group = true
  # Creates an ASG
  ha_mode              = var.use_fck_nat_instance_ha_mode                 
  # eip_allocation_ids   = ["eipalloc-abc1234"] # Allocation ID of an existing EIP
  use_cloudwatch_agent = false
  # When using Spot, make sure to use multiple instance types to avoid issues caused by instance type shortage
  # use_spot_instances = false                 # Enables Cloudwatch agent and have metrics reported

  instance_type = var.nat_instance_type

  update_route_tables = true
  
  route_tables_ids = {
    # Assumes one subnet per az
    "${each.key}" = one(module.subnets.az_private_route_table_ids_map[each.key])
  }

  # Transpose so we get a map per route table ID, if there are more than one per AZ
  #{for id, azs in transpose(module.subnets.az_private_route_table_ids_map[each.key]) : one(azs) => id if one(azs) == each.key}
  # { for id, azs in transpose(module.subnets.az_private_route_table_ids_map) : one(azs) => id }
  #  {
  #   "your-rtb-name-A" = "rtb-abc1234Foo"
  #   "your-rtb-name-B" = "rtb-abc1234Bar"
  # }
}

resource "aws_eip" "nat_ips" {
  for_each = var.assign_elastic_ips ? toset(var.zones) : []
  domain   = "vpc"

  depends_on = [
    module.vpc
  ]
}

// VPC Endpoints

// Gateway Endpoint for S3

module "s3_endpoint_label" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  attributes = compact(concat(module.this.attributes, ["s3"]))
  enabled    = var.enable_s3_endpoint
  context    = module.this.context
}

resource "aws_vpc_endpoint" "s3" {
  count        = var.enable_s3_endpoint ? 1 : 0
  vpc_id       = module.vpc.vpc_id
  service_name = format("com.amazonaws.%s.s3", var.aws_region)

  route_table_ids = module.subnets.private_route_table_ids

  tags = module.s3_endpoint_label.tags
}

# module "vpc_endpoints" {
#   source = "cloudposse/vpc/aws//modules/vpc-endpoints"
#   version     = "1.1.0"

#   vpc_id = module.vpc.vpc_id

#   gateway_vpc_endpoints = {
#     "s3" = {
#       name = "s3"
#       policy = jsonencode({
#         Version = "2012-10-17"
#         Statement = [
#           {
#             Action = [
#               "s3:*",
#             ]
#             Effect    = "Allow"
#             Principal = "*"
#             Resource  = "*"
#           },
#         ]
#       })
#     }
#   }
# }
