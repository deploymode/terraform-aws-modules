# Provider used to authenticate with destination account

provider "aws" {
  alias   = "replica"
  region  = var.destination_region
  profile = var.destination_profile

  dynamic "assume_role" {
    for_each = var.destination_role_arn == null ? [] : ["role"]

    content {
      role_arn = var.destination_role_arn
    }
  }
}
