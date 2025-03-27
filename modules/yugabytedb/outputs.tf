/**
 * Outputs for YugabyteDB module
 */

output "cluster_name" {
  description = "Name of the YugabyteDB cluster"
  value       = var.cluster_name
}

output "instance_group" {
  description = "Instance group for YugabyteDB nodes"
  value       = google_compute_region_instance_group_manager.yugabyte_mig.instance_group
}

output "ysql_connection_string" {
  description = "YSQL connection string"
  value       = "postgresql://yugabyte@${google_compute_forwarding_rule.yugabyte_ysql.ip_address}:5433/yugabyte?sslmode=require"
}

output "health_check_self_link" {
  description = "Self link of the health check"
  value       = google_compute_health_check.yugabyte_health_check.self_link
}

output "ilb_ip" {
  description = "IP of the internal load balancer"
  value       = google_compute_forwarding_rule.yugabyte_ysql.ip_address
}

output "region" {
  description = "Region of the YugabyteDB cluster"
  value       = var.region
}

output "node_count" {
  description = "Number of nodes in the YugabyteDB cluster"
  value       = var.node_count
} 