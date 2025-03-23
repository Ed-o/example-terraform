provider "google" {
  project = var.project_id
  region  = var.region
}

module "vpc" {
  source = "../../modules/vpc"
  
  project_id   = var.project_id
  vpc_name     = "${var.environment}-vpc"
  subnet_name  = "${var.environment}-subnet"
  region       = var.region
  ip_cidr_range = var.subnet_cidr
}

module "gke" {
  source = "../../modules/gke"
  
  project_id    = var.project_id
  cluster_name  = "${var.environment}-${var.cluster_name}"
  region        = var.region
  network       = module.vpc.vpc_name
  subnetwork    = module.vpc.subnet_name
  node_locations = var.node_locations
  min_master_version = var.gke_version
  
  depends_on = [module.vpc]
}

module "node_pool" {
  source = "../../modules/node_pool"
  
  project_id    = var.project_id
  cluster_name  = module.gke.cluster_name
  location      = var.region
  node_count    = var.node_count
  machine_type  = var.machine_type
  disk_size_gb  = var.disk_size_gb
  
  depends_on = [module.gke]
}
