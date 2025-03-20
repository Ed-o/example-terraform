variable "setup" {
  type = map
  default = {
    name		= "test"
    environment		= "uat"
    base_url		= "test.platformnamegoeshere.com"
    external_url	= ""
    alt_url		= "uat.platformnamegoeshere.com"
    creator		= "terraform"
    account		= "987654321"
  }
}

variable "network_settings" {
  type = map
  default = {
    shared_network 	= "true"
    region 		= "eu-west-1"
    vpc_cidr_base 	= "10.60"
    vpc_cidr		= "10.60.0.0/16"
    dns_enabled		= "true"
    dns_zone		= "Z0987654321987654321"
    dns_lookups		= "test.product.internal"
    tls_enabled		= "true"
    log_retention       = "1"
    shared_network      = "true"
    # If network is shared you will need to provide these :
    vpc_id		= "vpc-0987654321"
    internet_gw_id	= "igw-0987654321"
    ecs_task_role       = "ecs_task_role"
    ecs_exec_role       = "ecs_exec_role"
    log_encryption_role = "log_encryption_role"
    log_encryption_key  = "987654321-1234-4321-1234-987654321"
    msteams_enabled     = "false"
  }
}

variable "network_subnets" {
  default = {
    new = {}
    private = {
      subnet-main-a = { id = "subnet-0987654321" }
      subnet-main-b = { id = "subnet-0987654321" }
    }
    public = {
      subnet-main-a = { id = "subnet-0987654321" }
      subnet-main-b = { id = "subnet-0987654321" }
    }
  }
}

variable "storage" {
  type = map
  default = {
    efs_database_enable = false
    efs_images_enable = true
    efs_images_movecold = "AFTER_7_DAYS"    # 1, 7, 14, 30, 60 or 90
  }
}

variable "loadbalancer" {
  type = map
  default = {
    loadbalancer_enabled = false
    loadbalancer_shared = "product-uat"
    loadbalancer_shared_http = "arn:aws:elasticloadbalancing:eu-west-1:987654321:listener/app/product/987654321/123456789"
    loadbalancer_shared_https = "arn:aws:elasticloadbalancing:eu-west-1:987654321:listener/app/product/987654321/123456789"
    loadbalancer_url = "product-987654321.eu-west-1.elb.amazonaws.com"
    loadbalancer_public = false       # true = public subnets, false = privare subnets
    port_in = 443
    protocol_in = "HTTPS"
    port_out = 443
    protocol_out = "HTTPS"
    visibility = "internal"             # global / internal (who can see site)
    aws_waf_enabled = "true"		# This is conrtrolled in the aws/environment folder not here
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
    awskmskey = "arn:aws:kms:eu-west-1:987654321:key/987654321-1234-4321-5678-987654321"
    # If one of the following is blank it is taken from AWS-secrets (see database.tf for explanation)
    database_master_username = "root"
    database_master_password = ""
    database_app_database = "product"
    database_app_username = "dbusername"
    database_app_password = ""
    aws_access_key_id = "AK987654321987654321"
    aws_secret_access_key = "<secret>"
  }
}


variable "software" {
  default = {
    product = {
      name = "product"
      enabled = true
      repo = "987654321.dkr.ecr.eu-west-1.amazonaws.com/product:v1.2.3.4"
      repoarn = "arn:aws:ecr:eu-west-1:987654321:repository/product"
      port = "8000"
      cpu = "1024"
      memory = "2048"
      desired_count = 2
      max_capacity = 9
      environment = {
        APP_NAME = "test"
        APP_ID="test"
      }
    }
    nginx = {
      name = "nginx"
      enabled = false
      repo = "987654321.dkr.ecr.eu-west-1.amazonaws.com/nginx:latest"
      repoarn = "arn:aws:ecr:eu-west-1:987654321:repository/product"
      port = "80"
      public = true
      cpu = "256"
      memory = "512"
      desired_count = 1
      max_capacity = 2
    }
    mysql = {
      name = "mysql"
      ecs_enabled = false
      rds_servers_enabled = true
      rds_serverless_enabled = false
      local_enabled = false
      ### ----> This section for RDS
      rdscount = 1
      rdssize = "db.t4g.medium"
      rdsengine = "5.7.mysql_aurora.2.11.3"
      skip_final_snapshot = true
      ### ----> This section for ECS
      repo = "987654321.dkr.ecr.eu-west-1.amazonaws.com/mysql:latest"
      repoarn = "arn:aws:ecr:eu-west-1:987654321:repository/product"
      port = "3306"
      cpu = "256"
      memory = "512"
      desired_count = 1
      max_capacity = 1
      ### ----> This section for using a local DB (not setting one up)
      # Todo
    }
    redis = {
      name = "redis"
      aws_redis_enabled = false
      ecs_redis_enabled = true
      ### ----> This section for ECS Redis
      repo = "987654321.dkr.ecr.eu-west-1.amazonaws.com/redis:latest"
      repoarn = "arn:aws:ecr:eu-west-1:987654321:repository/product"
      port = "6379"
      cpu = "256"
      memory = "512"
      desired_count = 1
      max_capacity = 1
      ### ----> This section for ElastiCache Redis
      redis_param_group = "default.redis6.x"
      redis_size = "cache.t4g.micro" 
      redis_engine_version = "6.2"
    }
    clamav = {
      name = "clamav"
      enabled = true
      repo = "987654321.dkr.ecr.eu-west-1.amazonaws.com/clamav:latest"
      repoarn = "arn:aws:ecr:eu-west-1:987654321:repository/product"
      port = "3310"
      cpu = "512"
      memory = "4096"
      desired_count = 1
      max_capacity = 1
    }
    bastion = {
      name = "bastion"
      enabled = true
      repo = "987654321.dkr.ecr.eu-west-1.amazonaws.com/bastion:latest"
      repoarn = "arn:aws:ecr:eu-west-1:987654321:repository/product"
      port = "80"
      cpu = "256"
      memory = "512"
      environment = {
        # DB_IMPORT = "s3://dbimport/test.sql"
        DB_IMPORT = ""
        BASTION_COMMAND = ""
      }
    }
  }
}



