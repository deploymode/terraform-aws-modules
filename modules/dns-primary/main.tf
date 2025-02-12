locals {
  dns_soa_config = "awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400"
  zone_recs_map  = { for zone in var.record_config : "${zone.name}${zone.root_zone}.${zone.type}" => zone }
  dnssec_zones   = { for k, v in var.domains : k => v if v.dnssec_enabled == true }
}

resource "aws_route53_zone" "root" {
  for_each = var.domains

  name    = each.key
  comment = "DNS zone for the ${each.key} root domain"
  tags    = module.this.tags
}

resource "aws_route53_record" "soa" {
  for_each = aws_route53_zone.root

  allow_overwrite = true
  zone_id         = aws_route53_zone.root[each.key].zone_id
  name            = aws_route53_zone.root[each.key].name
  type            = "SOA"
  ttl             = "60"

  records = [
    "${aws_route53_zone.root[each.key].name_servers[0]}. ${local.dns_soa_config}"
  ]
}

resource "aws_route53_record" "dnsrec" {
  for_each = local.zone_recs_map

  name    = format("%s%s", each.value.name, each.value.root_zone)
  type    = each.value.type
  zone_id = aws_route53_zone.root[each.value.root_zone].zone_id
  ttl     = each.value.ttl

  records = each.value.records
}

module "dnssec" {
  # source  = "ugns/route53-dnssec/aws"
  # version = "1.1.0"
  source = "git::https://github.com/deploymode/terraform-aws-route53-dnssec.git?ref=tags/1.1.1"

  for_each = local.dnssec_zones

  name = each.key

  zones = {
    "${each.key}" = {
      zone_id = aws_route53_zone.root[each.key].zone_id
    }
  }

  context = module.this.context
}

resource "aws_route53_hosted_zone_dnssec" "default" {
  for_each = local.dnssec_zones

  hosted_zone_id = aws_route53_zone.root[each.key].zone_id
}