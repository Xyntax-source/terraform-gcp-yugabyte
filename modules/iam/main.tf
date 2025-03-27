/**
 * IAM Module for YugabyteDB deployment
 * Sets up Workload Identity Federation and necessary IAM roles
 */

# Create a Workload Identity Pool
resource "google_iam_workload_identity_pool" "pool" {
  workload_identity_pool_id = var.workload_identity_pool_id
  display_name              = "YugabyteDB Workload Identity Pool"
  description               = "Identity pool for YugabyteDB deployment"
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

# Assign roles to the service account
resource "google_project_iam_member" "compute_admin" {
  project = var.project_id
  role    = "roles/compute.admin"
  member  = "serviceAccount:${google_service_account.yugabyte_sa.email}"
}

resource "google_project_iam_member" "network_admin" {
  project = var.project_id
  role    = "roles/compute.networkAdmin"
  member  = "serviceAccount:${google_service_account.yugabyte_sa.email}"
}

resource "google_project_iam_member" "storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.yugabyte_sa.email}"
}

resource "google_project_iam_member" "service_account_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.yugabyte_sa.email}"
} 