terraform {
  required_version = ">= 0.14.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.64.0"
    }
    github = {
      source  = "integrations/github"
      # Temporarily limit due to bug https://github.com/integrations/terraform-provider-github/issues/2008
      version = "< 5.41.0"
    }
  }
}

# provider "github" {}