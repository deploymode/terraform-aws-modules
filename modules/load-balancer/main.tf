locals {
  public_dns_name = var.dns_prefix == "" ? data.aws_route53_zone.selected[0].name : join(".", [var.dns_prefix, data.aws_route53_zone.selected[0].name])
}

module "alb" {
  source                    = "git::https://github.com/cloudposse/terraform-aws-alb.git?ref=tags/0.19.0"
  namespace                 = module.this.namespace
  stage                     = module.this.stage
  name                      = module.this.name
  attributes                = module.this.attributes
  delimiter                 = module.this.delimiter
  vpc_id                    = var.vpc_id
  security_group_ids        = var.alb_security_group_ids
  subnet_ids                = var.public_subnet_ids
  target_group_name         = module.label.id
  http_ingress_cidr_blocks  = var.allowed_ipv4_cidr_blocks
  https_ingress_cidr_blocks = var.allowed_ipv4_cidr_blocks
  # target_group_port                       = var.target_group_port
  internal                                = false
  http_port                               = var.http_port
  https_port                              = var.https_port
  http_enabled                            = var.http_enabled
  https_enabled                           = var.https_enabled
  http_redirect                           = var.http_to_https_redirect
  certificate_arn                         = var.certificate_arn
  access_logs_enabled                     = var.access_logs_enabled
  alb_access_logs_s3_bucket_force_destroy = true
  access_logs_region                      = var.aws_region
  cross_zone_load_balancing_enabled       = true
  http2_enabled                           = true
  deletion_protection_enabled             = false
  tags                                    = var.tags
  # Timeouts
  deregistration_delay = var.deregistration_delay
  idle_timeout         = var.idle_timeout
  # Health check
  health_check_path                = var.health_check_path
  health_check_timeout             = var.health_check_timeout
  health_check_healthy_threshold   = var.health_check_healthy_threshold
  health_check_unhealthy_threshold = var.health_check_unhealthy_threshold
  health_check_interval            = var.health_check_interval
  health_check_matcher             = var.health_check_matcher
}

// Restrict ingress for ALB
resource "aws_security_group_rule" "http" {
  count             = length(var.allowed_ipv6_cidr_blocks) > 0 ? 1 : 0
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  ipv6_cidr_blocks  = var.allowed_ipv6_cidr_blocks
  security_group_id = module.alb.security_group_id
}

resource "aws_security_group_rule" "https" {
  count             = length(var.allowed_ipv6_cidr_blocks) > 0 ? 1 : 0
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  ipv6_cidr_blocks  = var.allowed_ipv6_cidr_blocks
  security_group_id = module.alb.security_group_id
}

data "aws_route53_zone" "selected" {
  count   = var.hosted_zone_id != "" ? 1 : 0
  zone_id = var.hosted_zone_id
  # name         = var.hosted_zone_name
  private_zone = false
}

// CloudFront to serve pages from S3
module "cloudfront_s3_cdn" {
  source                   = "git::https://github.com/cloudposse/terraform-aws-cloudfront-s3-cdn.git?ref=tags/0.35.0"
  context                  = module.this.context
  aliases                  = var.aliases
  acm_certificate_arn      = var.cf_certificate_arn
  compress                 = true
  encryption_enabled       = true
  use_regional_s3_endpoint = true
  website_enabled          = false
  minimum_protocol_version = "TLSv1.2_2019"
  allowed_methods          = ["HEAD", "GET"]
  error_document           = var.error_document
  index_document           = var.index_document
  origin_force_destroy     = var.remove_objects_on_destroy
  custom_error_response = [{
    error_caching_min_ttl = 600
    error_code            = 404
    response_code         = 200
    response_page_path    = format("/%s", var.index_document)
  }]
}

// Block public ACLs for CloudFront origin bucket
resource "aws_s3_bucket_public_access_block" "cloudfront_s3_cdn_bucket_block_public" {
  bucket = module.cloudfront_s3_cdn.s3_bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# resource "aws_s3_bucket_object" "index" {
#   bucket       = module.cloudfront_s3_cdn.s3_bucket
#   key          = "index.html"
#   source       = "${var.html_source_path}/index.html"
#   content_type = "text/html"
#   etag         = md5(file("${var.html_source_path}/index.html"))
# }

// Create Route 53 record for web app (OPTIONAL)
resource "aws_route53_record" "default" {
  count   = var.hosted_zone_id != "" ? 1 : 0
  zone_id = var.hosted_zone_id
  name    = local.public_dns_name
  type    = "A"

  failover_routing_policy {
    type = "PRIMARY"
  }

  set_identifier = "Primary"

  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = module.alb.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "failover" {
  count   = var.hosted_zone_id != "" ? 1 : 0
  zone_id = var.hosted_zone_id
  name    = local.public_dns_name
  type    = "A"

  failover_routing_policy {
    type = "SECONDARY"
  }

  set_identifier = "Secondary"

  alias {
    name                   = module.cloudfront_s3_cdn.cf_domain_name
    zone_id                = module.cloudfront_s3_cdn.cf_hosted_zone_id
    evaluate_target_health = true
  }
}
