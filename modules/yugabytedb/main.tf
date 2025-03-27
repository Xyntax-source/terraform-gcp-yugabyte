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

# Create instance template for YugabyteDB nodes
resource "google_compute_instance_template" "yugabyte_template" {
  name_prefix  = "${var.prefix}${var.cluster_name}-template-"
  machine_type = var.node_type
  tags         = ["${var.prefix}${var.cluster_name}"]

  disk {
    source_image = data.google_compute_image.yugabyte_image.self_link
    auto_delete  = true
    boot         = true
    disk_size_gb = var.disk_size
    disk_type    = "pd-ssd"
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
  }

  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create managed instance group for YugabyteDB
resource "google_compute_region_instance_group_manager" "yugabyte_mig" {
  name               = "${var.prefix}${var.cluster_name}-mig"
  base_instance_name = "${var.prefix}${var.cluster_name}"
  region             = var.region
  target_size        = var.node_count

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

  auto_healing_policies {
    health_check      = google_compute_health_check.yugabyte_health_check.id
    initial_delay_sec = 300
  }
}

# Create health check for YugabyteDB instances
resource "google_compute_health_check" "yugabyte_health_check" {
  name                = "${var.prefix}${var.cluster_name}-health-check"
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3

  tcp_health_check {
    port = "9000"
  }
}

# Create a regional internal load balancer for YugabyteDB
resource "google_compute_region_backend_service" "yugabyte_ilb" {
  name                  = "${var.prefix}${var.cluster_name}-ilb"
  region                = var.region
  load_balancing_scheme = "INTERNAL"
  health_checks         = [google_compute_health_check.yugabyte_health_check.id]

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

# Create startup script
resource "local_file" "startup_script" {
  content = templatefile("${path.module}/templates/startup.sh.tpl", {
    yb_version         = var.yb_version
    cluster_name       = var.cluster_name
    replication_factor = var.replication_factor
    region             = var.region
  })
  filename        = "${path.module}/startup.sh"
  file_permission = "0755"
}

# Upload startup script to GCS
resource "google_storage_bucket_object" "startup_script" {
  name    = "startup-${var.cluster_name}.sh"
  bucket  = var.script_bucket
  content = local_file.startup_script.content
} 