variable "cert_domain_name" {
  type        = string
  description = "Domain name for ACM cert"
}

variable "hosted_zone_name" {
  type        = string
  description = "Route53 hosted zone name. Defaults to `cert_domain_name` if value is empty."
  default     = ""
}

variable "auto_verify" {
  type        = bool
  description = "Set to true if Terraform should perform certification validation. This will also create a hosted zone. Ignored if validation_method is not \"DNS\"."
  default     = false
}

variable "wait_for_certificate_issued" {
  type        = bool
  description = "Set to true if Terraform should wait for cert validation"
  default     = true
}

variable "alternative_domain_prefixes" {
  type        = list(string)
  description = "A list of subdomains of domain_name or '*' that should be SANs in the issued certificate"
  default     = []
}

variable "alternative_domains" {
  type        = list(string)
  description = "A list of domain names that should be SANs in the issued certificate"
  default     = []
}

variable "wildcard_all" {
  type        = bool
  description = "Set to true if Terraform should create a wildcard certificate for all subdomains of domain_name"
  default     = false
}

variable "validation_method" {
  type        = string
  default     = "DNS"
  description = "Method to use for validation, DNS or EMAIL"
}
