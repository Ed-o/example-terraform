# main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = var.network_settings.region
  allowed_account_ids = [ var.setup.account ]
}

