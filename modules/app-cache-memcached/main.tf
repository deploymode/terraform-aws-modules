module "memcached_label" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  attributes = ["memcached"]
  context    = module.this.context
}

module "memcached" {
  source  = "cloudposse/elasticache-memcached/aws"
  version = "0.19.0"

  // Networking
  vpc_id                  = var.vpc_id
  subnets                 = var.subnet_ids
  availability_zones      = var.availability_zones
  availability_zone       = var.az_mode == "single-az" ?  one(var.availability_zones) : null
  allowed_security_groups = [module.memcached_allowed_sg.id]

  // DNS
  zone_id       = var.zone_id
  dns_subdomain = var.dns_subdomain

  // Memcached infra & HA
  az_mode       = var.az_mode
  cluster_size  = var.cluster_size
  instance_type = var.instance_type
  maintenance_window = var.maintenance_window

  // Memcached settings    
  engine_version                     = var.engine_version
  apply_immediately                  = true
  elasticache_parameter_group_family = var.elasticache_parameter_group_family
  max_item_size                      = var.max_item_size
  transit_encryption_enabled = var.transit_encryption_enabled

  context = module.memcached_label.context
}

# Security group which is allowed access to memcached
# This can be assigned to other resources, such as the ECS task
module "memcached_allowed_sg" {
  source  = "cloudposse/security-group/aws"
  version = "2.2.0"

  attributes = ["allowed"]

  security_group_description = "Services which need memcached access can be assigned this security group"

  create_before_destroy = true

  # Allow unlimited egress
  allow_all_egress = true

  rules = []

  vpc_id = var.vpc_id

  context = module.memcached_label.context
}
