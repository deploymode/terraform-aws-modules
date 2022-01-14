output "ses_domain_identity_arn" {
  value       = module.ses.ses_domain_identity_arn
  description = "The ARN of the SES domain identity"
}

output "ses_domain_identity_verification_token" {
  value       = module.ses.ses_domain_identity_verification_token
  description = "A code which when added to the domain as a TXT record will signal to SES that the owner of the domain has authorised SES to act on their behalf. The domain identity will be in state 'verification pending' until this is done. See below for an example of how this might be achieved when the domain is hosted in Route 53 and managed by Terraform. Find out more about verifying domains in Amazon SES in the AWS SES docs."
}

output "ses_dkim_tokens" {
  value       = module.ses.ses_dkim_tokens
  description = "A list of DKIM Tokens which, when added to the DNS Domain as CNAME records, allows for receivers to verify that emails were indeed authorized by the domain owner."
}

output "send_email_role" {
  value       = module.send_email_role.arn
  description = "Role which allows sending email"
}

output "email_domain" {
  value       = var.domain
  description = "Email domain configured in SES"
}

output "user_name" {
  value       = try(module.ses.user_name, "")
  description = "Normalized IAM user name."
}

output "user_arn" {
  value       = try(module.ses.user_arn, "")
  description = "The ARN assigned by AWS for this user."
}

output "user_unique_id" {
  value       = try(module.ses.user_unique_id, "")
  description = "The unique ID assigned by AWS."
}

output "secret_access_key" {
  sensitive   = true
  value       = try(module.ses.secret_access_key, "")
  description = "The IAM secret for usage with SES API. This will be written to the state file in plain text."
}
output "ses_smtp_password" {
  sensitive   = true
  value       = try(module.ses.ses_smtp_password, "")
  description = "The SMTP password. This will be written to the state file in plain text."
}

output "access_key_id" {
  value       = try(module.ses.access_key_id, "")
  description = "The SMTP user which is access key ID."
}

output "iam_key_id_ssm_param_arn" {
  value       = lookup(module.store_write.arn_map, var.iam_key_secret_ssm_param_path, "")
  description = "The SSM parameter store path where the SMTP user access key ID is stored."
}

output "iam_key_secret_ssm_param_arn" {
  value       = lookup(module.store_write.arn_map, var.iam_key_secret_ssm_param_path, "")
  description = "The SSM parameter store path where the SMTP user access key secret is stored."
}
