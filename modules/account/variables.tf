variable "org_feature_set" {
  type        = string
  default     = "ALL"
  description = "Organisation feature set. Specify \"ALL\" (default) or \"CONSOLIDATED_BILLING\"."
}

# https://gist.github.com/shortjared/4c1e3fe52bdfa47522cfe5b41e5d6f22
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

variable "account_email_format" {
  type        = string
  description = "Account email format string. Used in combination with `name`, e.g. ops-%s@deploymode.com"
}

variable "account_role_name" {
  type        = string
  description = "IAM role that Organization automatically preconfigures in the new member account"
  default     = "OrganizationAccountAccessRole"
}

variable "accounts" {
  type        = map(object({
    iam_user_access_to_billing = bool
  }))
  description = "Accounts to be created. Map of account names to settings."
}

// Account Settings
variable "minimum_password_length" {
  type        = number
  default     = 12
  description = "Min password length"
}

variable "allow_users_to_change_password" {
  type        = bool
  default     = true
  description = "Allow users to change passwords"
}
