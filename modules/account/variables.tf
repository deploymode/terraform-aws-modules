variable "org_feature_set" {
  type        = string
  default     = "ALL"
  description = "Organisation feature set. Specify \"ALL\" (default) or \"CONSOLIDATED_BILLING\"."
}

variable "org_service_access_principals" {
  type        = list(string)
  default     = []
  description = "List of AWS service principal names for which you want to enable integration with your organization. This is typically in the form of a URL, such as service-abbreviation.amazonaws.com. Organization must have feature_set set to ALL. For additional information, see the AWS Organizations User Guide."
}

variable "org_enabled_policy_types" {
  type        = list(string)
  description = "List of Organizations policy types to enable in the Organization Root. Organization must have feature_set set to ALL. For additional information about valid policy types (e.g. SERVICE_CONTROL_POLICY and TAG_POLICY), see the [AWS Organizations API Reference](https://docs.aws.amazon.com/organizations/latest/APIReference/API_EnablePolicyType.html)"
  default     = []
}

variable "account_email" {
  type        = string
  description = "Account email format string. Used in combination with `name`, e.g. ops-%s@deploymode.com"
}

variable "account_role_name" {
  type        = string
  description = "IAM role that Organization automatically preconfigures in the new member account"
  default     = "OrganizationAccountAccessRole"
}

variable "accounts" {
  type        = list(string)
  description = "List of account names to create"
}
