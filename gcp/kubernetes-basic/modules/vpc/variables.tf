variable "project_id" {
  description = "The project ID to host the network in"
  type        = string
}

variable "vpc_name" {
  description = "The name of the VPC network"
  type        = string
}

variable "subnet_name" {
  description = "The name of the subnetwork"
  type        = string
}

variable "region" {
  description = "The region of the subnetwork"
  type        = string
}

variable "ip_cidr_range" {
  description = "The IP CIDR range of the subnetwork"
  type        = string
  default     = "10.0.0.0/24"
}

variable "secondary_ip_range_pods" {
  description = "The IP CIDR range for pods"
  type        = string
  default     = "10.1.0.0/16"
}

variable "secondary_ip_range_services" {
  description = "The IP CIDR range for services"
  type        = string
  default     = "10.2.0.0/20"
}
