variable "hosted_zone_name" {
  type        = string
  description = "Route53 hosted zone name. Defaults to `domain_name` if value is \"\"."
  default     = ""
}

variable "cert_domain_name" {
  type        = string
  description = "Domain name for ACM cert"
}

variable "auto_verify" {
  type        = bool
  description = "Set to true if Terraform should perform certification validation. This will also create a hosted zone."
  default     = false
}

variable "wait_for_certificate_issued" {
  type        = bool
  description = "Set to true if Terraform should wait for cert validation"
  default     = true
}

variable "alternative_domain_prefixes" {
  type        = list(string)
  description = "A list of subdomains of domain_name that should be SANs in the issued certificate"
  default = [
  ]
}

variable "alternative_domains" {
  type        = list(string)
  description = "A list of domain names that should be SANs in the issued certificate"
  default = [
  ]
}
