resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  project                 = var.project_id
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  project       = var.project_id
  region        = var.region
  network       = google_compute_network.vpc.self_link
  ip_cidr_range = var.ip_cidr_range
  
  private_ip_google_access = true
  
  secondary_ip_range {
    range_name    = "${var.subnet_name}-pods"
    ip_cidr_range = var.secondary_ip_range_pods
  }
  
  secondary_ip_range {
    range_name    = "${var.subnet_name}-services"
    ip_cidr_range = var.secondary_ip_range_services
  }
}

# Firewall rule for internal cluster communication
resource "google_compute_firewall" "internal" {
  name    = "${var.vpc_name}-allow-internal"
  project = var.project_id
  network = google_compute_network.vpc.name
  
  allow {
    protocol = "icmp"
  }
  
  allow {
    protocol = "tcp"
  }
  
  allow {
    protocol = "udp"
  }
  
  source_ranges = [var.ip_cidr_range, var.secondary_ip_range_pods, var.secondary_ip_range_services]
}

# NAT Router to allow egress traffic from private instances
resource "google_compute_router" "router" {
  name    = "${var.vpc_name}-router"
  project = var.project_id
  region  = var.region
  network = google_compute_network.vpc.self_link
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.vpc_name}-nat"
  project                            = var.project_id
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
