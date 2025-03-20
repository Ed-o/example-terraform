output "load_balancer_url" {
  description = "The URL of the load balancer"
  value = module.modules.load_balancer_url
}

output "Main_external_URL" {
  description = "The incoming URL of this environment"
  value = var.setup.external_url
}

output "External_base_URL" {
  description = "The incoming URL of this environment"
  value = var.setup.base_url
}

