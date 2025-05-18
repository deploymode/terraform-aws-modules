module "redis_label" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  attributes = ["redis", "cache"]
  context    = module.this.context
}

module "redis" {
  source  = "cloudposse/elasticache-redis/aws"
  version = "1.9.1"

  # Networking
  availability_zones = var.availability_zones
  vpc_id             = var.vpc_id
  subnets            = var.subnet_ids

  # DNS
  zone_id       = var.zone_id
  dns_subdomain = var.dns_subdomain

  # Security groups
  create_security_group      = true
  allowed_security_group_ids = [module.redis_allowed_sg.id]

  # Redis infra
  cluster_mode_enabled       = var.cluster_mode_enabled
  cluster_size               = var.cluster_size
  instance_type              = var.instance_type
  apply_immediately          = true
  automatic_failover_enabled = false
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  # Redis/Valkey settings
  engine         = var.engine
  engine_version = var.engine_version
  family         = var.family
  port           = var.port
  auth_token     = var.password

  context = module.redis_label.context
}

# Security group which is allowed access to redis
# This can be assigned to other resources, such as the ECS task
module "redis_allowed_sg" {
  source  = "cloudposse/security-group/aws"
  version = "2.2.0"

  attributes = ["allowed"]

  security_group_description = "Services which need Redis access can be assigned this security group"

  create_before_destroy = true

  # Allow unlimited egress
  allow_all_egress = true

  rules = []

  vpc_id = var.vpc_id

  context = module.redis_label.context
}
