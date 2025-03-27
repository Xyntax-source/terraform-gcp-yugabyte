/**
 * VPC Module for YugabyteDB deployment
 * Creates a VPC with public and private subnets
 */

# Create VPC
resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  description             = "VPC for YugabyteDB deployment"
  
  # Enable more secure routing options
  routing_mode            = "REGIONAL"
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

# Create Cloud Routers for NAT Gateways (one per zone for redundancy)
resource "google_compute_router" "router" {
  count   = min(length(var.private_subnets), 3) # Up to 3 routers for redundancy
  name    = "${var.vpc_name}-router-${count.index}"
  region  = var.region
  network = google_compute_network.vpc.self_link
}

# Create NAT Gateways (one per zone for redundancy)
resource "google_compute_router_nat" "nat" {
  count                              = min(length(var.private_subnets), 3) # Up to 3 NATs for redundancy
  name                               = "${var.vpc_name}-nat-${count.index}"
  router                             = google_compute_router.router[count.index].name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  
  # Configure NAT for all private subnets
  dynamic "subnetwork" {
    for_each = google_compute_subnetwork.private_subnet
    content {
      name                    = subnetwork.value.self_link
      source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
    }
  }
  
  # Configure router logs
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Create firewall rule for internal communication with specific tags
resource "google_compute_firewall" "internal" {
  name    = "${var.vpc_name}-allow-internal"
  network = google_compute_network.vpc.name
  description = "Allow internal traffic between YugabyteDB instances"
  priority = 1000

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

  # Use a more specific network tag for targeting
  target_tags = ["yugabyte-internal"]
  source_tags = ["yugabyte-internal"]
  
  # Fallback to source ranges if needed
  source_ranges = var.use_network_tags ? null : concat(var.public_subnets, var.private_subnets)
}

# Create firewall rule for SSH access with specific tags
resource "google_compute_firewall" "ssh" {
  name        = "${var.vpc_name}-allow-ssh"
  network     = google_compute_network.vpc.name
  description = "Allow SSH access to YugabyteDB instances"
  priority    = 1000

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # Use a tag for targeting SSH access
  target_tags   = ["yugabyte-ssh"]
  source_ranges = var.allowed_ssh_ranges
  
  # Add log configuration
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Create firewall rule for YugabyteDB access with specific tags
resource "google_compute_firewall" "yugabyte" {
  name        = "${var.vpc_name}-allow-yugabyte"
  network     = google_compute_network.vpc.name
  description = "Allow access to YugabyteDB ports"
  priority    = 1000

  allow {
    protocol = "tcp"
    ports    = ["7000", "9000", "6379", "9042", "5433", "7100", "9100"]
  }

  # Use a tag for targeting database access
  target_tags   = ["yugabyte-db"]
  source_ranges = var.allowed_db_ranges
  
  # Add log configuration
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Create a deny-all egress firewall rule except for essential services
resource "google_compute_firewall" "restrict_egress" {
  name        = "${var.vpc_name}-restrict-egress"
  network     = google_compute_network.vpc.name
  description = "Restrict outbound traffic to essential services only"
  direction   = "EGRESS"
  priority    = 1100
  
  # All is denied by this rule, specific allows will be created
  deny {
    protocol = "all"
  }
  
  # Apply only if egress restrictions are enabled
  count       = var.restrict_egress ? 1 : 0
  
  # Apply to all instances with this tag
  target_tags = ["yugabyte-restricted"]
}

# Allow essential outbound services if egress is restricted
resource "google_compute_firewall" "allow_essential_egress" {
  name        = "${var.vpc_name}-allow-essential-egress"
  network     = google_compute_network.vpc.name
  description = "Allow outbound traffic to essential services"
  direction   = "EGRESS"
  priority    = 1000
  
  allow {
    protocol = "tcp"
    ports    = ["443", "80"] # HTTPS and HTTP
  }
  
  # Apply only if egress restrictions are enabled
  count       = var.restrict_egress ? 1 : 0
  
  # Apply to all instances with this tag
  target_tags = ["yugabyte-restricted"]
  
  # Destination ranges (restrict to Google APIs and services)
  destination_ranges = ["*.googleapis.com", "*.gcr.io"]
} 