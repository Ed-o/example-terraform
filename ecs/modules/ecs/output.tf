output "load_balancer_url" {
  description = "The URL of the load balancer"
  value = var.loadbalancer.loadbalancer_enabled ? aws_alb.product[0].dns_name : "No ALB URL"
}

