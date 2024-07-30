# main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
#  backend "s3" {
#    bucket = "terraform-network"
#    key    = "terraform/network/infrastructure"
#    region = "eu-west-1"
#  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = var.setup.region
  allowed_account_ids = [ var.setup.account ]
}



