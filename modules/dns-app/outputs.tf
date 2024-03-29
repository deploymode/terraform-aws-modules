output "cert_arn" {
  value       = module.acm_request_certificate.arn
  description = "Certificate ARN"
}

output "zone_id" {
  value       = data.aws_route53_zone.existing.id
  description = "Route53 zone ID"
}

output "zone_name" {
  value       = local.zone_name
  description = "Route53 zone name"
}
