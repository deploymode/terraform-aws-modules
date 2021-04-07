output "hosted_zone_id" {
  # value       = var.create_hosted_zone ? join("", aws_route53_zone.default.*.id) : join("", data.aws_route53_zone.existing.*.id)
  value       = join("", aws_route53_zone.default.*.id)
  description = "Route53 hosted zone ID"
}

output "hosted_zone_name_servers" {
  value       = aws_route53_zone.default.*.name_servers
  description = "Route53 hosted zone name servers"
}

output "cert_arn" {
  value       = module.acm_request_certificate.arn
  description = "Certificate ARN"
}
