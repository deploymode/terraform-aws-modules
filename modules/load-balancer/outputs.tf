output "alb_name" {
  description = "The ARN suffix of the ALB"
  value       = module.alb.alb_name
}

output "alb_arn" {
  description = "The ARN of the ALB"
  value       = module.alb.alb_arn
}

output "alb_arn_suffix" {
  description = "The ARN suffix of the ALB"
  value       = module.alb.alb_arn_suffix
}

output "alb_dns_name" {
  description = "DNS name of ALB"
  value       = module.alb.alb_dns_name
}

output "alb_zone_id" {
  description = "The ID of the zone which ALB is provisioned"
  value       = module.alb.alb_zone_id
}

output "alb_security_group_id" {
  description = "The security group ID of the ALB"
  value       = module.alb.security_group_id
}

output "alb_default_target_group_arn" {
  description = "The default target group ARN"
  value       = module.alb.default_target_group_arn
}

output "alb_http_listener_arn" {
  description = "The ARN of the HTTP listener"
  value       = module.alb.http_listener_arn
}

output "alb_listener_arns" {
  description = "A list of all the listener ARNs"
  value       = module.alb.listener_arns
}

output "alb_access_logs_bucket_id" {
  description = "The S3 bucket ID for access logs"
  value       = module.alb.access_logs_bucket_id
}

output "cf_id" {
  value       = module.cloudfront_s3_cdn.cf_id
  description = "ID of AWS CloudFront distribution"
}

output "cf_arn" {
  value       = module.cloudfront_s3_cdn.cf_arn
  description = "ARN of AWS CloudFront distribution"
}

output "cf_status" {
  value       = module.cloudfront_s3_cdn.cf_status
  description = "Current status of the distribution"
}

output "cf_domain_name" {
  value       = module.cloudfront_s3_cdn.cf_domain_name
  description = "Domain name corresponding to the distribution"
}

output "cf_etag" {
  value       = module.cloudfront_s3_cdn.cf_etag
  description = "Current version of the distribution's information"
}

output "cf_hosted_zone_id" {
  value       = module.cloudfront_s3_cdn.cf_hosted_zone_id
  description = "CloudFront Route 53 zone ID"
}

output "cf_alias_hostnames" {
  value       = var.aliases
  description = "CloudFront DNS alias hostnames"
}

output "s3_bucket" {
  value       = module.cloudfront_s3_cdn.s3_bucket
  description = "Name of S3 bucket"
}

output "s3_bucket_domain_name" {
  value       = module.cloudfront_s3_cdn.s3_bucket_domain_name
  description = "Domain of S3 bucket"
}
