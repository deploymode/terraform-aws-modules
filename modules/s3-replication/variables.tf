variable "aws_account_id" {
  type        = string
  description = "Source account id performing replication"
}

variable "aws_region" {
  type        = string
  description = "Source account's region (for performing replication)"
}

variable "source_profile" {
  type        = string
  description = "Profile for authenticating on source account"
  default     = null
}

variable "source_role_arn" {
  type        = string
  description = "IAM role to assume for authenticating on source account"
  default     = null
}

variable "destination_region" {
  type        = string
  description = "Destination account's region (for receiving replication)"
}

variable "destination_profile" {
  type        = string
  description = "Profile for authenticating on destination account"
  default     = null
}

variable "destination_role_arn" {
  type        = string
  description = "IAM role to assume for authenticating on destination account"
  default     = null
}

variable "bucket_names" {
  type = map(object({
    acl          = string
    block_public = bool
    cors_rules = list(object({
      allowed_headers = list(string)
      allowed_methods = list(string)
      allowed_origins = list(string)
      expose_headers  = list(string)
      max_age_seconds = number
    }))
  }))
  default     = {}
  description = "Map of objects, specifying buckets for replication from source to destination and the ACL of the DR bucket"
}

variable "force_destroy" {
  type        = bool
  default     = false
  description = "A boolean string that indicates all objects should be deleted from the bucket so that the bucket can be destroyed without error. These objects are not recoverable"
}

variable "versioning_enabled" {
  type        = bool
  default     = true
  description = "A state of versioning. Versioning is a means of keeping multiple variants of an object in the same bucket"
}

variable "noncurrent_version_expiration_days" {
  type        = number
  default     = 90
  description = "Specifies when noncurrent object versions expire"
}

variable "noncurrent_version_transition_days" {
  type        = number
  default     = 30
  description = "Specifies when noncurrent object versions transition to Standard-IA"
}

variable "expiration_days" {
  type        = number
  default     = 90
  description = "Number of days after which to expunge the objects"
}

variable "replica_bucket_suffix" {
  type        = string
  default     = "dr"
  description = "Suffix to add to replicated buckets to make the names unique"
}
