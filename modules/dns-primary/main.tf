
locals {
  dns_soa_config = "awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400"
  domains_set    = toset(var.domains)
}

resource "aws_route53_zone" "root" {
  for_each = local.domains_set

  name    = each.value
  comment = "DNS zone for the ${each.value} root domain"
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