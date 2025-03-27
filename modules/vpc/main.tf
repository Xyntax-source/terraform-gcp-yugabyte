/**
 * VPC Module for YugabyteDB deployment
 * Creates a VPC with public and private subnets
 */

# Create VPC
resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  description             = "VPC for YugabyteDB deployment"
}

# Create public subnet
resource "google_compute_subnetwork" "public_subnet" {
  count         = length(var.public_subnets)
  name          = "${var.vpc_name}-public-subnet-${count.index}"
  ip_cidr_range = var.public_subnets[count.index]
  region        = var.region
  network       = google_compute_network.vpc.self_link
  
  # Enable Flow Logs for better network monitoring
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Create private subnet
resource "google_compute_subnetwork" "private_subnet" {
  count         = length(var.private_subnets)
  name          = "${var.vpc_name}-private-subnet-${count.index}"
  ip_cidr_range = var.private_subnets[count.index]
  region        = var.region
  network       = google_compute_network.vpc.self_link
  private_ip_google_access = true
  
  # Enable Flow Logs for better network monitoring
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Create Cloud Router for NAT Gateway
resource "google_compute_router" "router" {
  name    = "${var.vpc_name}-router"
  region  = var.region
  network = google_compute_network.vpc.self_link
}

# Create NAT Gateway
resource "google_compute_router_nat" "nat" {
  name                               = "${var.vpc_name}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  
  subnetwork {
    name                    = google_compute_subnetwork.private_subnet[0].self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

# Create firewall rule for internal communication
resource "google_compute_firewall" "internal" {
  name    = "${var.vpc_name}-allow-internal"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "icmp"
  }

  source_ranges = concat(var.public_subnets, var.private_subnets)
}

# Create firewall rule for SSH access
resource "google_compute_firewall" "ssh" {
  name    = "${var.vpc_name}-allow-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.allowed_ssh_ranges
}

# Create firewall rule for YugabyteDB access
resource "google_compute_firewall" "yugabyte" {
  name    = "${var.vpc_name}-allow-yugabyte"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["7000", "9000", "6379", "9042", "5433", "7100", "9100"]
  }

  source_ranges = var.allowed_db_ranges
} 