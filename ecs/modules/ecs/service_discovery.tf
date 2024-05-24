# Service Discovery

# Info on this section here :
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_service

resource "aws_service_discovery_private_dns_namespace" "ecsconnect_dns" {
  name        = "${var.setup.name}.product.internal"
  description = "product dns"
  vpc         = "${data.aws_vpc.selected.id}"
}

resource "aws_service_discovery_public_dns_namespace" "pub_ecsconnect_dns" {
  name        = "discover.${var.setup.base_url}"
  # name        = "discover.${var.setup.name}.product.net"
  description = "product dns"
}

resource "aws_service_discovery_service" "product_app" {
  name = "product_app"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.ecsconnect_dns.id
    dns_records {
      ttl  = 30
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_service_discovery_service" "mysql_app_name" {
  count = var.software.mysql.rds_serverless_enabled || var.software.mysql.rds_servers_enabled ? 1 : 0
  name = "mysql_app"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.ecsconnect_dns.id
    dns_records {
      ttl  = 30
      type = "CNAME"
    }
    routing_policy = "WEIGHTED"
  }
  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_service_discovery_service" "mysql_app_ip" {
  count = var.software.mysql.ecs_enabled ? 1 : 0
  name = "mysql_app"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.ecsconnect_dns.id
    dns_records {
      ttl  = 30
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_service_discovery_service" "nginx_app" {
  count = ((var.software.nginx.enabled == true) && (var.loadbalancer.loadbalancer_enabled == "false")) ? 1 : 0
  name = "nginx_app"
  dns_config {
    namespace_id = aws_service_discovery_public_dns_namespace.pub_ecsconnect_dns.id
    dns_records {
      ttl  = 30
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_service_discovery_service" "redis_app_name" {
  count = (var.software.redis.aws_redis_enabled ) ? 1 : 0
  name = "redis_app"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.ecsconnect_dns.id
    dns_records {
      ttl  = 30
      type = "CNAME"
    }
    routing_policy = "WEIGHTED"
  }
  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_service_discovery_service" "redis_app_ip" {
  count = (var.software.redis.ecs_redis_enabled ) ? 1 : 0
  name = "redis_app"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.ecsconnect_dns.id
    dns_records {
      ttl  = 30
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_service_discovery_service" "clamav_app" {
  name = "clamav_app"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.ecsconnect_dns.id
    dns_records {
      ttl  = 30
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
  health_check_custom_config {
    failure_threshold = 1
  }
}


