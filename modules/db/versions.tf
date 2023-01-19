terraform {
  required_version = ">= 0.12.29"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.61.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.4.3"
    }
  }
}
