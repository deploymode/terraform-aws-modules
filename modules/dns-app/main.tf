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
  source                            = "git::https://github.com/cloudposse/terraform-aws-acm-request-certificate.git?ref=tags/0.16.0"
  enabled                           = module.this.enabled
  domain_name                       = var.cert_domain_name
  process_domain_validation_options = var.auto_verify
  ttl                               = "300"
  subject_alternative_names = formatlist("%s.%s", var.alternative_domain_prefixes,
    compact(concat(
      var.alternative_domains
      [var.cert_domain_name]
    ))
  )
  wait_for_certificate_issued = var.wait_for_certificate_issued
  zone_name                   = data.aws_route53_zone.existing.name
}
