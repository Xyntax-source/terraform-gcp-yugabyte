/**
 * Outputs for VPC module
 */

output "vpc_id" {
  description = "ID of the created VPC"
  value       = google_compute_network.vpc.self_link
}

output "vpc_name" {
  description = "Name of the created VPC"
  value       = google_compute_network.vpc.name
}

output "vpc_self_link" {
  description = "Self link of the created VPC"
  value       = google_compute_network.vpc.self_link
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = google_compute_subnetwork.public_subnet[*].self_link
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = google_compute_subnetwork.private_subnet[*].self_link
}

output "public_subnet_self_links" {
  description = "Self links of the public subnets"
  value       = google_compute_subnetwork.public_subnet[*].self_link
}

output "private_subnet_self_links" {
  description = "Self links of the private subnets"
  value       = google_compute_subnetwork.private_subnet[*].self_link
}

output "nat_ips" {
  description = "IPs of the NAT gateways"
  value       = google_compute_router_nat.nat[*].nat_ips
}

output "firewall_rules" {
  description = "List of created firewall rules"
  value = [
    google_compute_firewall.internal.self_link,
    google_compute_firewall.ssh.self_link,
    google_compute_firewall.yugabyte.self_link
  ]
} 