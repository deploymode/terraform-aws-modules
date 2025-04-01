resource "aws_ecs_cluster" "fargate_cluster" {
  count = module.this.enabled ? 1 : 0
  name  = module.this.id

  setting {
    name  = "containerInsights"
    value = var.container_insights_enabled ? "enabled" : "disabled"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = module.this.tags
}

resource "aws_ecs_cluster_capacity_providers" "default" {
  cluster_name = join("", aws_ecs_cluster.fargate_cluster.*.name)

  capacity_providers = var.capacity_providers

  default_capacity_provider_strategy {
    capacity_provider = var.default_capacity_provider
    weight            = 100
    base              = 1
  }
}

resource "aws_service_discovery_private_dns_namespace" "default" {
  count       = (module.this.enabled && var.create_service_discovery_namespace) ? 1 : 0
  name        = join(".", [module.this.namespace, "local"])
  description = module.this.id
  vpc         = var.vpc_id
  tags        = module.this.tags
}
