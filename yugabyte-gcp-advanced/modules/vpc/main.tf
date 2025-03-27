terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

# VPC Network
resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  routing_mode           = "GLOBAL"
}

# Subnets
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.vpc_name}-subnet"
  ip_cidr_range = var.subnet_cidr
  network       = google_compute_network.vpc.id
  region        = var.region
}

# Cloud NAT for private instances
resource "google_compute_router" "router" {
  name    = "${var.vpc_name}-router"
  network = google_compute_network.vpc.id
  region  = var.region
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.vpc_name}-nat"
  router                            = google_compute_router.router.name
  region                            = google_compute_router.router.region
  nat_ip_allocate_option           = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# Firewall Rules
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.vpc_name}-allow-internal"
  network = google_compute_network.vpc.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = [var.subnet_cidr]
  target_tags   = ["internal"]
}

# YugabyteDB specific firewall rules
resource "google_compute_firewall" "yugabyte_ports" {
  name    = "${var.vpc_name}-yugabyte-ports"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["9000", "7000", "6379", "9042", "5433", "22"]
  }

  source_ranges = var.allowed_ips
  target_tags   = ["yugabyte"]
}

resource "google_compute_firewall" "yugabyte_intra" {
  name    = "${var.vpc_name}-yugabyte-intra"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["7100", "9100"]
  }

  source_ranges = [var.subnet_cidr]
  target_tags   = ["yugabyte"]
}

# Outputs
output "vpc_id" {
  value = google_compute_network.vpc.id
}

output "subnet_id" {
  value = google_compute_subnetwork.subnet.id
}

output "network_name" {
  value = google_compute_network.vpc.name
}

output "subnet_name" {
  value = google_compute_subnetwork.subnet.name
} 