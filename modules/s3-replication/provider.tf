# Main provider - overwrites the one defined in root terragrunt.hcl file

provider "aws" {
  alias   = "source"
  region  = var.aws_region
  profile = var.source_profile

  dynamic "assume_role" {
    for_each = var.source_role_arn == null ? [] : ["role"]

    content {
      role_arn = var.source_role_arn
    }
  }
}
