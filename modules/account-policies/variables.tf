variable "policies" {
  type        = map(any)
  description = "Map of policy names to policy statements"
  default     = {}
}
