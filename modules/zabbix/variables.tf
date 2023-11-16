variable "setup" {
  type = map
  default = {
    name = "zabbix"
    environment = "dev"
    domain = "zabbix.dev.companyname.com"
    creator = "terraform"
    account = "987654321"
  }
}

variable "network_settings" {
  type = map
  default = {
    region 		= "eu-west-1"
    vpc_cidr_base 	= "10.128"
    vpc_cidr		= "10.128.0.0/16"
    vpc_name		= "zabbix-vpc"
    shared_network      = "true"
    vpc_id		= "vpc-04987654321"
    internet_gw_id	= "igw-0c987654321"
    high_availability   = "false"
    dns_enabled		= "true"
    dns_zone		= "Z0987654321DNS"
    tls_enabled		= "true"
  }
}

variable "network_subnets" {
  default = {
    subnet-main-a = {
      name			= "zabbix-a"
      public_cidr_range         = ".255.0/27"
      private_cidr_range        = ".255.32/27"
      availability_zone		= "a"
    }
    subnet-main-b = {
      name 			= "zabbix-b"
      public_cidr_range		= ".255.96/27"
      private_cidr_range	= ".255.128/27"
      availability_zone		= "b"
    }
#    subnet-main-c = {
#      name 			= "zabbix-c"
#      public_cidr_range	= ".255.160/27"
#      private_cidr_range	= ".255.192/27"
#      availability_zone	= "c"
#    }
  }
}

variable "loadbalancer" {
  type = map
  default = {
    loadbalancer_enabled = false
    loadbalancer_public = false       # true = public subnets, false = privare subnets
    aws_certificate_arn = false
  }
}


variable "mail" {
  type = map
  default = {
    mailhog_enabled = false
  }
}

variable "secrets" {
  type = map
  default = {
    awskmskey = "arn:aws:kms:eu-west-1:987654321:key/987654321-1234-4321-1234-987654321"
    database_master_username = "zabroot"
  }
}


variable "software" {
  default = {
    zabbix = {
      launch_type = "FARGATE"        # Options = FARGATE or EC2
      repo = "987654321.dkr.ecr.eu-west-1.amazonaws.com/zabbix:latest"
      webport = "80"
      intport = "10051"
      cpu = "256"
      memory = "512"
      min_size = 1
      max_size = 2
      desired_size = 1
      # Options for ec2 :
      aws_instance_type="t3.small"
      aws_ami="ami-06987654321"
      public_key = "myKeyGoewsHere"
      # Options for ECS
    }
    database = {
      rds_servers_enabled = "false"
      rds_serverless_enabled = "true"
      # Options for RDS Servers :
      aws_db_instance_type="db.t3.small"
      aws_db_backup_days=3
      engine="mysql"
      engine_version="5.7.41"
      # Options for RDS Serverless :
      
    }
  }
}



