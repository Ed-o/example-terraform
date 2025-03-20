# main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "terraform-prod"
    key    = "terraform/prod/infrastructure"
    region = "eu-west-1"
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = var.setup.region
  allowed_account_ids = [ var.setup.account ]
}

module "modules" {
  source = "../../modules"
  setup = var.setup
  values = var.values
  alerts = var.alerts
}


