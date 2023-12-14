variable "domains" {
  type        = map(object({
    dnssec_enabled = optional(bool, false)
  }))
  description = "Domains to set up zones for. Map of domain name to settings."
  default     = {}
}

variable "record_config" {
  description = "DNS record config for additional DNS records to be added to the primary zone"
  type = list(object({
    root_zone = string
    name      = string
    type      = string
    ttl       = string
    records   = list(string)
  }))
  default = []
}
