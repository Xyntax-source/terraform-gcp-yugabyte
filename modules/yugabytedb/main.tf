/**
 * YugabyteDB Module for GCP deployment
 * Sets up a YugabyteDB cluster with high availability
 */

data "google_compute_image" "yugabyte_image" {
  family  = "centos-7"
  project = "centos-cloud"
}

data "google_compute_zones" "available" {
  region = var.region
}

# Create disk for YugabyteDB data
resource "google_compute_disk" "yugabyte_data_disk" {
  count   = var.node_count
  name    = "${var.prefix}${var.cluster_name}-data-disk-${count.index}"
  type    = "pd-ssd"
  zone    = element(data.google_compute_zones.available.names, count.index % length(data.google_compute_zones.available.names))
  size    = var.data_disk_size
  
  # Enable disk encryption
  disk_encryption_key {
    kms_key_self_link = var.kms_key_self_link != "" ? var.kms_key_self_link : null
  }
}

# Create instance template for YugabyteDB nodes
resource "google_compute_instance_template" "yugabyte_template" {
  name_prefix  = "${var.prefix}${var.cluster_name}-template-"
  machine_type = var.node_type
  tags         = ["${var.prefix}${var.cluster_name}", "yugabyte-internal", "yugabyte-ssh", "yugabyte-db"]

  disk {
    source_image = data.google_compute_image.yugabyte_image.self_link
    auto_delete  = true
    boot         = true
    disk_size_gb = var.disk_size
    disk_type    = "pd-ssd"
    
    # Enable boot disk encryption
    disk_encryption_key {
      kms_key_self_link = var.kms_key_self_link != "" ? var.kms_key_self_link : null
    }
  }

  network_interface {
    network    = var.vpc_id
    subnetwork = var.private_subnet_id

    # No public IP if using private subnets
    dynamic "access_config" {
      for_each = var.use_public_ip ? [1] : []
      content {
        # Ephemeral public IP
      }
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key)}"
    startup-script = templatefile("${path.module}/templates/startup.sh.tpl", {
      yb_version         = var.yb_version
      cluster_name       = var.cluster_name
      replication_factor = var.replication_factor
      region             = var.region
      prefix             = var.prefix
    })
  }

  service_account {
    email  = var.service_account_email
    # Use more specific scopes instead of cloud-platform
    scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write"
    ]
  }

  # Allow time for the template to be created
  lifecycle {
    create_before_destroy = true
  }

  # Enable shielded VM features for enhanced security
  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  # Schedule automatic OS patch management
  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = var.use_preemptible_instances
  }
}

# Create distribution policy to ensure instances are spread across zones
resource "google_compute_region_instance_group_manager" "yugabyte_mig" {
  name               = "${var.prefix}${var.cluster_name}-mig"
  base_instance_name = "${var.prefix}${var.cluster_name}"
  region             = var.region
  target_size        = var.node_count

  # Ensure distribution across zones
  distribution_policy_zones = data.google_compute_zones.available.names
  
  # Use updated instance template
  version {
    instance_template = google_compute_instance_template.yugabyte_template.id
  }

  named_port {
    name = "yb-master"
    port = 7000
  }

  named_port {
    name = "yb-tserver"
    port = 9000
  }

  named_port {
    name = "ysql"
    port = 5433
  }

  # Auto-healing policy with more comprehensive health check
  auto_healing_policies {
    health_check      = google_compute_health_check.yugabyte_health_check.id
    initial_delay_sec = 300
  }

  # Add update policy for controlled rollouts
  update_policy {
    type                  = "PROACTIVE"
    minimal_action        = "REPLACE"
    max_surge_fixed       = 1
    max_unavailable_fixed = 0
    replacement_method    = "SUBSTITUTE"
  }
}

# Create a more comprehensive health check for YugabyteDB
resource "google_compute_health_check" "yugabyte_health_check" {
  name                = "${var.prefix}${var.cluster_name}-health-check"
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3

  # Check the tserver HTTP endpoint instead of just TCP
  http_health_check {
    port         = 9000
    request_path = "/status"
  }

  # Add a secondary TCP health check for the database port
  tcp_health_check {
    port = 5433
  }
}

# Create a regional internal load balancer for YugabyteDB
resource "google_compute_region_backend_service" "yugabyte_ilb" {
  name                  = "${var.prefix}${var.cluster_name}-ilb"
  region                = var.region
  load_balancing_scheme = "INTERNAL"
  health_checks         = [google_compute_health_check.yugabyte_health_check.id]
  protocol              = "TCP"
  session_affinity      = "CLIENT_IP"
  timeout_sec           = 30

  backend {
    group = google_compute_region_instance_group_manager.yugabyte_mig.instance_group
  }
}

# Create forwarding rule for YugabyteDB YSQL
resource "google_compute_forwarding_rule" "yugabyte_ysql" {
  name                  = "${var.prefix}${var.cluster_name}-ysql"
  region                = var.region
  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.yugabyte_ilb.id
  all_ports             = false
  ports                 = ["5433"]
  network               = var.vpc_id
  subnetwork            = var.private_subnet_id
}

# Create forwarding rule for YugabyteDB Admin UI
resource "google_compute_forwarding_rule" "yugabyte_ui" {
  name                  = "${var.prefix}${var.cluster_name}-ui"
  region                = var.region
  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.yugabyte_ilb.id
  all_ports             = false
  ports                 = ["7000"]
  network               = var.vpc_id
  subnetwork            = var.private_subnet_id
} 