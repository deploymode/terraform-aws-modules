###
# Creates and verifies certificate for application within existing hosted zone.
#
###

locals {
  zone_name = var.hosted_zone_name == "" ? var.cert_domain_name : var.hosted_zone_name
}

data "aws_route53_zone" "existing" {
  name = local.zone_name
}

module "acm_request_certificate" {
  source                            = "git::https://github.com/cloudposse/terraform-aws-acm-request-certificate.git?ref=tags/0.13.1"
  enabled                           = module.this.enabled
  domain_name                       = var.cert_domain_name
  process_domain_validation_options = var.auto_verify
  ttl                               = "300"
  subject_alternative_names = compact(concat(
    formatlist("%s.%s", var.alternative_domain_prefixes, var.cert_domain_name),
    formatlist("%s.%s", var.alternative_domain_prefixes, var.alternative_domains)
  ))
  wait_for_certificate_issued = var.wait_for_certificate_issued
  zone_name                   = data.aws_route53_zone.existing.name
}
