output "zones" {
  value       = aws_route53_zone.root
  description = "DNS zones"
}

output "ds_records" {
  value       = { for zone, records in module.dnssec : zone => records["ds_record"] }
  description = "DS records"
}
