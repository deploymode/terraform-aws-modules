provider "aws" {
  # The AWS provider to use to make changes in the DNS primary account
  alias  = "primary"
  region = var.region

  assume_role {
    role_arn = var.primary_role_arn
  }
}

provider "aws" {
  # The AWS provider to use to make changes in the target (delegated) account
  alias  = "delegated"
  region = var.region

  assume_role {
    role_arn = var.delegated_role_arn
  }
}
