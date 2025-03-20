# main.tf
provider "google" {
  credentials = file(var.credentials_file)
  project     = var.project_id
  region      = var.primary_region
}

# Variables
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "credentials_file" {
  description = "Path to the GCP credentials file"
  type        = string
  default     = "service-account.json"
}

variable "primary_region" {
  description = "Primary GCP region"
  type        = string
  default     = "us-central1"
}

variable "secondary_region" {
  description = "Secondary GCP region"
  type        = string
  default     = "us-west1"
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "multi-region-gke"
}

variable "node_count" {
  description = "Number of nodes per zone"
  type        = number
  default     = 1
}

variable "machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "e2-standard-2"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.25.5-gke.1500"
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "gke-network"
}

variable "mongodb_instance_name" {
  description = "Name of the MongoDB instance"
  type        = string
  default     = "mongodb-instance"
}

variable "mongodb_version" {
  description = "MongoDB version"
  type        = string
  default     = "4.4"
}

variable "mongodb_tier" {
  description = "MongoDB machine tier"
  type        = string
  default     = "db-f1-micro"
}

# Network
resource "google_compute_network" "gke_network" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

# Subnets
resource "google_compute_subnetwork" "primary_subnet" {
  name          = "primary-subnet"
  ip_cidr_range = "10.1.0.0/16"
  network       = google_compute_network.gke_network.id
  region        = var.primary_region
}

resource "google_compute_subnetwork" "secondary_subnet" {
  name          = "secondary-subnet"
  ip_cidr_range = "10.2.0.0/16"
  network       = google_compute_network.gke_network.id
  region        = var.secondary_region
}

# Primary GKE Cluster
resource "google_container_cluster" "primary" {
  name               = "${var.cluster_name}-primary"
  location           = var.primary_region
  min_master_version = var.kubernetes_version
  network            = google_compute_network.gke_network.id
  subnetwork         = google_compute_subnetwork.primary_subnet.id

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  # Enable Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Enable network policy
  network_policy {
    enabled = true
  }

  # Enable private cluster
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  # IP allocation policy
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "10.105.0.0/16"
    services_ipv4_cidr_block = "10.106.0.0/16"
  }
}

# Primary Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.cluster_name}-primary-node-pool"
  location   = var.primary_region
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count

  node_config {
    machine_type = var.machine_type
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      env = "prod"
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }
}

# Secondary GKE Cluster
resource "google_container_cluster" "secondary" {
  name               = "${var.cluster_name}-secondary"
  location           = var.secondary_region
  min_master_version = var.kubernetes_version
  network            = google_compute_network.gke_network.id
  subnetwork         = google_compute_subnetwork.secondary_subnet.id

  remove_default_node_pool = true
  initial_node_count       = 1

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  network_policy {
    enabled = true
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.1.0/28"
  }

  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "10.201.0.0/16"
    services_ipv4_cidr_block = "10.202.0.0/16"
  }
}

# Secondary Node Pool
resource "google_container_node_pool" "secondary_nodes" {
  name       = "${var.cluster_name}-secondary-node-pool"
  location   = var.secondary_region
  cluster    = google_container_cluster.secondary.name
  node_count = var.node_count

  node_config {
    machine_type = var.machine_type
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      env = "prod"
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }
}

# MongoDB Instance (Using Cloud SQL since GCP doesn't have a native MongoDB service)
# Note: In a production environment, you might want to use MongoDB Atlas instead
resource "google_sql_database_instance" "mongodb" {
  name             = var.mongodb_instance_name
  database_version = "MYSQL_5_7"  # Cloud SQL doesn't support MongoDB directly
  region           = var.primary_region

  settings {
    tier = var.mongodb_tier
    availability_type = "REGIONAL"
    
    backup_configuration {
      enabled = true
      start_time = "02:00"
    }
    
    ip_configuration {
      ipv4_enabled = true
      private_network = google_compute_network.gke_network.id
    }
  }

  deletion_protection = false  # Set to true for production
}

# Load Balancer
resource "google_compute_global_address" "lb_ip" {
  name = "gke-lb-ip"
}

output "primary_cluster_endpoint" {
  value = google_container_cluster.primary.endpoint
}

output "secondary_cluster_endpoint" {
  value = google_container_cluster.secondary.endpoint
}

output "load_balancer_ip" {
  value = google_compute_global_address.lb_ip.address
}

output "mongodb_connection_name" {
  value = google_sql_database_instance.mongodb.connection_name
}

