terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

# Monitoring Dashboard
resource "google_monitoring_dashboard" "yugabyte_dashboard" {
  dashboard_json = jsonencode({
    displayName = "YugabyteDB Dashboard"
    gridLayout = {
      columns = "2"
      widgets = [
        {
          title   = "CPU Usage"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" resource.type=\"gce_instance\""
                }
              }
            }]
          }
        },
        {
          title   = "Memory Usage"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "metric.type=\"compute.googleapis.com/instance/memory/utilization\" resource.type=\"gce_instance\""
                }
              }
            }]
          }
        },
        {
          title   = "Disk Usage"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "metric.type=\"compute.googleapis.com/instance/disk/utilization\" resource.type=\"gce_instance\""
                }
              }
            }]
          }
        },
        {
          title   = "Network Traffic"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "metric.type=\"compute.googleapis.com/instance/network/received_bytes_count\" resource.type=\"gce_instance\""
                }
              }
            }]
          }
        }
      ]
    }
  })
}

# Alert Policies
resource "google_monitoring_alert_policy" "cpu_alert" {
  display_name = "High CPU Usage Alert"
  combiner     = "OR"
  conditions {
    display_name = "CPU usage is high"
    condition_threshold {
      filter     = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" resource.type=\"gce_instance\""
      duration   = "300s"
      comparison = "COMPARISON_GT"
      threshold_value = 0.8
    }
  }
  notification_channels = var.notification_channels
}

resource "google_monitoring_alert_policy" "memory_alert" {
  display_name = "High Memory Usage Alert"
  combiner     = "OR"
  conditions {
    display_name = "Memory usage is high"
    condition_threshold {
      filter     = "metric.type=\"compute.googleapis.com/instance/memory/utilization\" resource.type=\"gce_instance\""
      duration   = "300s"
      comparison = "COMPARISON_GT"
      threshold_value = 0.8
    }
  }
  notification_channels = var.notification_channels
}

resource "google_monitoring_alert_policy" "disk_alert" {
  display_name = "High Disk Usage Alert"
  combiner     = "OR"
  conditions {
    display_name = "Disk usage is high"
    condition_threshold {
      filter     = "metric.type=\"compute.googleapis.com/instance/disk/utilization\" resource.type=\"gce_instance\""
      duration   = "300s"
      comparison = "COMPARISON_GT"
      threshold_value = 0.8
    }
  }
  notification_channels = var.notification_channels
}

# Log-based metrics
resource "google_logging_metric" "yugabyte_errors" {
  name        = "yugabyte_errors"
  description = "Count of YugabyteDB error logs"
  filter      = "resource.type=\"gce_instance\" AND severity>=ERROR"
}

# Outputs
output "dashboard_url" {
  value = "https://console.cloud.google.com/monitoring/dashboards/custom/${google_monitoring_dashboard.yugabyte_dashboard.dashboard_id}"
} 