resource "aws_ecs_cluster" "fargate_cluster" {
  count = module.this.enabled ? 1 : 0
  name  = module.this.id

  capacity_providers = ["FARGATE_SPOT", "FARGATE"]

  default_capacity_provider_strategy {
    capacity_provider = var.default_capacity_provider
    weight            = 100
  }

  setting {
    name  = "containerInsights"
    value = var.container_insights_enabled ? "enabled" : "disabled"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_service_discovery_private_dns_namespace" "default" {
  count       = var.create_service_discovery_namespace ? 1 : 0
  name        = join(".", [module.this.namespace, "local"])
  description = module.this.id
  vpc         = var.vpc_id
}
