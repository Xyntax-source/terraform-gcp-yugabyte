/**
 * Outputs for IAM module
 */

output "service_account_email" {
  description = "Email of the service account"
  value       = google_service_account.yugabyte_sa.email
}

output "service_account_id" {
  description = "ID of the service account"
  value       = google_service_account.yugabyte_sa.id
}

output "workload_identity_pool_id" {
  description = "ID of the Workload Identity Pool"
  value       = google_iam_workload_identity_pool.pool.id
}

output "workload_identity_provider_name" {
  description = "Name of the Workload Identity Provider"
  value       = google_iam_workload_identity_pool_provider.provider.name
}

output "workload_identity_provider_id" {
  description = "ID of the Workload Identity Provider"
  value       = google_iam_workload_identity_pool_provider.provider.id
}

output "custom_role_id" {
  description = "ID of the custom role"
  value       = google_project_iam_custom_role.yugabyte_role.id
} 