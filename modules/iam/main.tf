/**
 * IAM Module for YugabyteDB deployment
 * Sets up Workload Identity Federation and necessary IAM roles
 */

# Create a Workload Identity Pool
resource "google_iam_workload_identity_pool" "pool" {
  workload_identity_pool_id = var.workload_identity_pool_id
  display_name              = "YugabyteDB Workload Identity Pool"
  description               = "Identity pool for YugabyteDB deployment"
  disabled                  = false
}

# Create a Workload Identity Provider for the pool
resource "google_iam_workload_identity_pool_provider" "provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.pool.workload_identity_pool_id
  workload_identity_pool_provider_id = var.workload_identity_provider_id
  display_name                       = "YugabyteDB Provider"
  description                        = "OIDC identity provider for YugabyteDB deployment"
  
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }
  
  oidc {
    issuer_uri = var.oidc_issuer_uri
    allowed_audiences = [var.allowed_audience]
  }
}

# Create a service account for YugabyteDB
resource "google_service_account" "yugabyte_sa" {
  account_id   = var.service_account_id
  display_name = "YugabyteDB Service Account"
  description  = "Service account for YugabyteDB deployment"
}

# Allow the external identity to impersonate the service account
resource "google_service_account_iam_binding" "workload_identity_binding" {
  service_account_id = google_service_account.yugabyte_sa.name
  role               = "roles/iam.workloadIdentityUser"
  members            = [
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.pool.name}/attribute.repository/${var.repo_name}"
  ]
}

# Create a custom role with only the required permissions
resource "google_project_iam_custom_role" "yugabyte_role" {
  role_id     = "${var.service_account_id}-role"
  title       = "YugabyteDB Deployment Role"
  description = "Custom role with minimal permissions for YugabyteDB deployment"
  permissions = [
    # Compute Instance permissions
    "compute.instances.create",
    "compute.instances.delete",
    "compute.instances.get",
    "compute.instances.list",
    "compute.instances.setMetadata",
    "compute.instances.setTags",
    "compute.instances.setLabels",
    "compute.instances.start",
    "compute.instances.stop",
    "compute.instances.reset",
    
    # Disk permissions
    "compute.disks.create",
    "compute.disks.delete",
    "compute.disks.get",
    "compute.disks.list",
    "compute.disks.use",
    
    # Network permissions
    "compute.networks.get",
    "compute.networks.use",
    "compute.networks.list",
    "compute.subnetworks.get",
    "compute.subnetworks.list",
    "compute.subnetworks.use",
    "compute.firewalls.get",
    "compute.firewalls.list",
    
    # Instance Group permissions
    "compute.instanceGroups.create",
    "compute.instanceGroups.delete",
    "compute.instanceGroups.get",
    "compute.instanceGroups.list",
    "compute.instanceGroups.use",
    "compute.instanceGroupManagers.create",
    "compute.instanceGroupManagers.delete",
    "compute.instanceGroupManagers.get",
    "compute.instanceGroupManagers.list",
    "compute.instanceGroupManagers.update",
    "compute.instanceTemplates.create",
    "compute.instanceTemplates.delete",
    "compute.instanceTemplates.get",
    "compute.instanceTemplates.list",
    "compute.instanceTemplates.useReadOnly",
    
    # Load Balancer permissions
    "compute.backendServices.create",
    "compute.backendServices.delete",
    "compute.backendServices.get",
    "compute.backendServices.list",
    "compute.backendServices.update",
    "compute.backendServices.use",
    "compute.healthChecks.create",
    "compute.healthChecks.delete",
    "compute.healthChecks.get",
    "compute.healthChecks.list",
    "compute.healthChecks.update",
    "compute.healthChecks.use",
    "compute.forwardingRules.create",
    "compute.forwardingRules.delete",
    "compute.forwardingRules.get",
    "compute.forwardingRules.list",
    
    # Storage permissions
    "storage.buckets.get",
    "storage.buckets.list",
    "storage.objects.create",
    "storage.objects.delete",
    "storage.objects.get",
    "storage.objects.list",
    
    # Logging and monitoring permissions
    "logging.logEntries.create",
    "logging.logEntries.list",
    "logging.logs.list",
    "monitoring.metricDescriptors.create",
    "monitoring.metricDescriptors.get",
    "monitoring.metricDescriptors.list",
    "monitoring.timeSeries.create"
  ]
}

# Assign the custom role to the service account
resource "google_project_iam_member" "yugabyte_custom_role" {
  project = var.project_id
  role    = google_project_iam_custom_role.yugabyte_role.id
  member  = "serviceAccount:${google_service_account.yugabyte_sa.email}"
}

# Monitor the service account for unusual activity
resource "google_project_iam_audit_config" "yugabyte_audit" {
  project = var.project_id
  service = "allServices"
  
  audit_log_config {
    log_type = "ADMIN_READ"
  }
  
  audit_log_config {
    log_type = "DATA_WRITE"
  }
  
  audit_log_config {
    log_type = "DATA_READ"
    exempted_members = []
  }
} 