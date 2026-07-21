terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = ">= 4.40.0"
    betteruptime = {
      source  = "BetterStackHQ/better-uptime"
      version = ">= 0.21.0"
    }
  }
}
