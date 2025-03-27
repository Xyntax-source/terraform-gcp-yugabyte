/**
 * Outputs for VPC module
 */

output "vpc_id" {
  description = "ID of the created VPC"
  value       = google_compute_network.vpc.id
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
  value       = google_compute_subnetwork.public_subnet[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = google_compute_subnetwork.private_subnet[*].id
}

output "public_subnet_self_links" {
  description = "Self links of the public subnets"
  value       = google_compute_subnetwork.public_subnet[*].self_link
}

output "private_subnet_self_links" {
  description = "Self links of the private subnets"
  value       = google_compute_subnetwork.private_subnet[*].self_link
}

output "nat_ip" {
  description = "IP address of the NAT gateway"
  value       = google_compute_router_nat.nat.nat_ip_allocate_option
} 