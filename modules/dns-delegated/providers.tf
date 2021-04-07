# provider "aws" {
#   # The AWS provider to use to make changes in the DNS primary account
#   alias  = "primary"
#   region = var.aws_region

#   #   assume_role {
#   #     role_arn = coalesce(var.import_role_arn, module.iam_roles.dns_terraform_role_arn)
#   #   }
# }

provider "aws" {
  # The AWS provider to use to make changes in the target (delegated) account
  alias  = "delegated"
  region = var.aws_region

  assume_role {
    role_arn = format("arn:aws:iam::${var.delegated_aws_account_id}:role/${var.delegated_role_name}") # coalesce(var.import_role_arn, module.iam_roles.terraform_role_arn)
  }
}
