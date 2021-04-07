module "label" {
  source     = "github.com/cloudposse/terraform-null-label.git?ref=0.19.2"
  namespace  = var.namespace
  name       = var.app
  stage      = var.stage
  delimiter  = var.delimiter
  attributes = compact(concat(var.attributes, ["endpoint"]))
  tags       = var.tags
}

// Security Group to associate with Interface endpoints

// Allows all traffic within VPC
resource "aws_security_group" "default" {
  vpc_id      = var.vpc_id
  name        = module.label.id
  description = "Allow traffic to VPC Interface endpoints"

  lifecycle {
    create_before_destroy = true
  }

  ingress {
    description = "TLS connections from VPC CIDR"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = module.label.tags
}

// VPC Endpoints

// Allow ECS service to reach CloudWatch Logs via VPC Endpoint

module "logs_endpoint_label" {
  source     = "github.com/cloudposse/terraform-null-label.git?ref=0.19.2"
  context    = module.label.context
  name       = "network"
  attributes = compact(concat(var.attributes, ["logs"]))
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id            = var.vpc_id
  service_name      = format("com.amazonaws.%s.logs", var.aws_region)
  vpc_endpoint_type = "Interface"

  subnet_ids = var.private_subnet_ids

  private_dns_enabled = var.enable_private_dns

  security_group_ids = compact(concat([aws_security_group.default.id],
  var.vpc_endpoint_logs_security_group_ids))

  tags = module.logs_endpoint_label.tags
}

module "ecr_dkr_endpoint_label" {
  source     = "github.com/cloudposse/terraform-null-label.git?ref=0.19.2"
  context    = module.label.context
  name       = "network"
  attributes = compact(concat(var.attributes, ["ecr_dkr"]))
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id            = var.vpc_id
  service_name      = format("com.amazonaws.%s.ecr.dkr", var.aws_region)
  vpc_endpoint_type = "Interface"

  subnet_ids = var.private_subnet_ids

  private_dns_enabled = var.enable_private_dns

  security_group_ids = compact(concat([aws_security_group.default.id],
  var.vpc_endpoint_ecr_security_group_ids))

  tags = module.ecr_dkr_endpoint_label.tags
}

module "ecr_api_endpoint_label" {
  source     = "github.com/cloudposse/terraform-null-label.git?ref=0.19.2"
  context    = module.label.context
  name       = "network"
  attributes = compact(concat(var.attributes, ["ecr_api"]))
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id            = var.vpc_id
  service_name      = format("com.amazonaws.%s.ecr.api", var.aws_region)
  vpc_endpoint_type = "Interface"

  subnet_ids = var.private_subnet_ids

  private_dns_enabled = var.enable_private_dns

  security_group_ids = compact(concat([aws_security_group.default.id],
  var.vpc_endpoint_ecr_security_group_ids))

  tags = module.ecr_api_endpoint_label.tags
}


module "ssm_endpoint_label" {
  source     = "github.com/cloudposse/terraform-null-label.git?ref=0.19.2"
  context    = module.label.context
  name       = "ssm"
  attributes = compact(concat(var.attributes, ["ssm"]))
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id            = var.vpc_id
  service_name      = format("com.amazonaws.%s.ssm", var.aws_region)
  vpc_endpoint_type = "Interface"

  subnet_ids = var.private_subnet_ids

  private_dns_enabled = var.enable_private_dns

  security_group_ids = compact(concat([aws_security_group.default.id],
  var.vpc_endpoint_ssm_security_group_ids))

  tags = module.ssm_endpoint_label.tags
}
