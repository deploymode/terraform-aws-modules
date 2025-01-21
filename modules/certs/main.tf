locals {
  zone_name = var.hosted_zone_name == "" ? var.cert_domain_name : var.hosted_zone_name

  # Determine prefixes including wildcards
  prefixes = distinct(concat(
    [for prefix in var.alternative_domain_prefixes : var.wildcard_all ? format("%s.%s", "*", prefix) : prefix if prefix != "*"],
    # If wildcard is applied to everything we don't need to add the individual prefixes
    var.wildcard_all ? ["*"] : var.alternative_domain_prefixes
  ))

  # Combine prefixes with domains
  subdomain_set = setproduct(
    local.prefixes,
    concat(var.alternative_domains, [var.cert_domain_name])
  )

  # Produce a list of subdomains
  subdomains = [ for subdomain in local.subdomain_set : format("%s.%s", subdomain[0], subdomain[1]) ]
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
  subject_alternative_names         = local.subdomains
  wait_for_certificate_issued = var.wait_for_certificate_issued
  zone_name                   = data.aws_route53_zone.existing.name
}
