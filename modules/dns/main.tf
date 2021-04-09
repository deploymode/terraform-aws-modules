locals {
  zone_name        = var.hosted_zone_name == "" ? var.cert_domain_name : var.hosted_zone_name
  zone_name_in_use = var.create_hosted_zone ? join("", aws_route53_zone.default.*.name) : join("", data.aws_route53_zone.existing.*.name)
}

resource "aws_route53_zone" "default" {
  count   = (module.this.enabled && var.create_hosted_zone) ? 1 : 0
  name    = local.zone_name
  comment = format("DNS zone for %s", local.zone_name)
  tags    = module.this.tags
}

data "aws_route53_zone" "existing" {
  count = ! var.create_hosted_zone ? 1 : 0
  name  = local.zone_name
}

module "acm_request_certificate" {
  source                            = "git::https://github.com/cloudposse/terraform-aws-acm-request-certificate.git?ref=tags/0.13.1"
  enabled                           = module.this.enabled
  domain_name                       = var.cert_domain_name
  process_domain_validation_options = var.auto_verify
  ttl                               = "300"
  subject_alternative_names         = compact(concat(formatlist("%s.%s", var.alternative_domain_prefixes, var.cert_domain_name), var.alternative_domains))
  wait_for_certificate_issued       = var.wait_for_certificate_issued
  # zone_name                         = join("", aws_route53_zone.default.*.name)
  zone_name = local.zone_name_in_use # var.create_hosted_zone ? join("", aws_route53_zone.default.*.name) : join("", data.aws_route53_zone.existing.*.name)

  depends_on = [
    aws_route53_zone.default
  ]
}

resource "aws_route53_record" "soa" {
  # for_each = aws_route53_zone.default

  allow_overwrite = true
  name            = aws_route53_zone.default[0].name
  type            = "SOA"
  ttl             = "60"
  zone_id         = aws_route53_zone.default[0].zone_id

  records = [
    "${aws_route53_zone.default[0].name_servers[0]}. awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400"
  ]
}
