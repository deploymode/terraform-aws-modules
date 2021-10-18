###
# Sets up Amazon SES for application mail. 
#
###

module "ses" {
  source  = "cloudposse/ses/aws"
  version = "0.20.2"

  domain        = var.domain
  zone_id       = var.zone_id
  verify_dkim   = var.verify_dkim
  verify_domain = var.verify_domain

  context = module.this.context
}
