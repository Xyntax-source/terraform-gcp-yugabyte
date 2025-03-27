output "ui" {
  sensitive = false
  value     = "http://${google_compute_instance.yugabyte_node.0.network_interface.0.access_config.0.nat_ip}:7000"
}
output "ssh_user" {
  sensitive = false
  value = "${var.ssh_user}"
}
output "ssh_key" {
  sensitive = false
  value     = "${var.ssh_private_key}"
}

output "JDBC" {
  sensitive =false
  value     = "postgresql://yugabyte@${google_compute_instance.yugabyte_node.0.network_interface.0.access_config.0.nat_ip}:5433"
}

output "YSQL"{
  sensitive = false
  value     = "ysqlsh -U yugabyte -h ${google_compute_instance.yugabyte_node.0.network_interface.0.access_config.0.nat_ip} -p 5433"
}

output "YCQL"{
  sensitive = false
  value     = "ycqlsh ${google_compute_instance.yugabyte_node.0.network_interface.0.access_config.0.nat_ip} 9042"
}

output "YEDIS"{
  sensitive = false
  value     = "redis-cli -h ${google_compute_instance.yugabyte_node.0.network_interface.0.access_config.0.nat_ip} -p 6379"
}

output "cluster_info" {
  description = "Information about the deployed cluster"
  value = {
    name = var.cluster_name
    node_count = var.node_count
    replication_factor = var.replication_factor
    region = var.region_name
    disk_size = var.disk_size
    machine_type = var.node_type
  }
}

output "node_ips" {
  description = "List of all node IPs"
  value = {
    public_ips = google_compute_instance.yugabyte_node[*].network_interface[0].access_config[0].nat_ip
    private_ips = google_compute_instance.yugabyte_node[*].network_interface[0].network_ip
  }
}

output "connection_strings" {
  description = "Connection strings for different interfaces"
  value = {
    ysql = "ysqlsh -U yugabyte -h ${google_compute_instance.yugabyte_node[0].network_interface[0].access_config[0].nat_ip} -p 5433"
    ycql = "ycqlsh ${google_compute_instance.yugabyte_node[0].network_interface[0].access_config[0].nat_ip} 9042"
    yedis = "redis-cli -h ${google_compute_instance.yugabyte_node[0].network_interface[0].access_config[0].nat_ip} -p 6379"
    jdbc = "postgresql://yugabyte@${google_compute_instance.yugabyte_node[0].network_interface[0].access_config[0].nat_ip}:5433"
  }
}
