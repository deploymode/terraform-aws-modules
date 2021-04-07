locals {
  zone_map = zipmap(var.zone_config[*].subdomain, var.zone_config[*].zone_name)
  ns_map   = zipmap(var.zone_config[*].subdomain, var.zone_config[*].name_servers)
}

data "aws_route53_zone" "root_zone" {
  for_each = local.zone_map

  name         = format("%s.", each.value)
  private_zone = false
}

resource "aws_route53_record" "root_ns" {
  # for_each = data.aws_route53_zone.root_zone
  for_each = local.ns_map

  allow_overwrite = true
  name            = each.key
  records         = each.value # aws_route53_zone.default[each.key].name_servers
  type            = "NS"
  ttl             = "30"
  zone_id         = data.aws_route53_zone.root_zone[each.key].zone_id
  # data.aws_route53_zone.root_zone[each.key].zone_id
}
