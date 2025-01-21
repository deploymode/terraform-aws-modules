locals {
  zone_name = var.hosted_zone_name == "" ? var.cert_domain_name : var.hosted_zone_name
}

data "aws_route53_zone" "existing" {
  name = local.zone_name
}

module "acm_request_certificate" {
  source                            = "cloudposse/acm-request-certificate/aws"
  version                           = "0.16.3"
  enabled                           = module.this.enabled
  domain_name                       = var.cert_domain_name
  validation_method                 = var.validation_method
  process_domain_validation_options = var.auto_verify
  ttl                               = "300"
  subject_alternative_names = length(var.alternative_domain_prefixes) == 0 ? var.alternative_domains : concat(
    var.alternative_domains,
    flatten([
      for prefix in var.alternative_domain_prefixes :
      formatlist("%s.%s", prefix,
        compact(concat(
          var.alternative_domains,
          [var.cert_domain_name]
        ))
      )
    ])
  )
  wait_for_certificate_issued = var.wait_for_certificate_issued
  zone_name                   = data.aws_route53_zone.existing.name
}
