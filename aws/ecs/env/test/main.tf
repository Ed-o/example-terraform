# main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
  backend "s3" {
    bucket = "terraform-uat"
    key    = "terraform/test"
    region = "eu-west-1"
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = var.network_settings.region
  allowed_account_ids = [ var.setup.account ] 
}

module "modules" {
  source = "../../modules/ecs"
  setup = var.setup
  network_settings = var.network_settings
  network_subnets = var.network_subnets
  loadbalancer = var.loadbalancer
  mail = var.mail
  software = var.software
  secrets = var.secrets
  storage = var.storage
}



