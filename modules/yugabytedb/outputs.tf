/**
 * Outputs for YugabyteDB module
 */

output "ysql_connection_string" {
  description = "YSQL connection string"
  value       = "postgresql://yugabyte@${google_compute_forwarding_rule.yugabyte_ysql.ip_address}:5433/yugabyte"
}

output "ilb_ip" {
  description = "IP of the YugabyteDB internal load balancer"
  value       = google_compute_forwarding_rule.yugabyte_ysql.ip_address
}

output "cluster_name" {
  description = "Name of the YugabyteDB cluster"
  value       = var.cluster_name
}

output "node_count" {
  description = "Number of nodes in the YugabyteDB cluster"
  value       = var.node_count
}

output "ui_url" {
  description = "URL for the YugabyteDB admin UI"
  value       = "http://${google_compute_forwarding_rule.yugabyte_ui.ip_address}:7000"
}

output "instance_group" {
  description = "Instance group for the YugabyteDB cluster"
  value       = google_compute_region_instance_group_manager.yugabyte_mig.instance_group
}

output "health_check_self_link" {
  description = "Self link of the health check"
  value       = google_compute_health_check.yugabyte_health_check.self_link
}

output "region" {
  description = "Region of the YugabyteDB cluster"
  value       = var.region
} 