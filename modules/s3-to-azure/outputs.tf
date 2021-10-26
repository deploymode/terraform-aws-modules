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
