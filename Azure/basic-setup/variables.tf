# variables.tf

variable "project_name" {
  description = "Name of project"
  type        = string
}

variable "location" {
  description = "Azure Region"
  type        = string
  default     = "westeurope"
}

variable "ssh_public_key" {
  description = "SSH public key"
  type        = string
}

variable "mysql_admin_username" {
  description = "Admin username for MySQL"
  type        = string
}

variable "mysql_admin_password" {
  description = "Admin password for MySQL"
  type        = string
  sensitive   = true
}
