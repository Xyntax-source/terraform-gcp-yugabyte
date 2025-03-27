/**
 * Outputs for IAM module
 */

output "service_account_email" {
  description = "Email of the created service account"
  value       = google_service_account.yugabyte_sa.email
}

output "workload_identity_pool_id" {
  description = "ID of the created Workload Identity Pool"
  value       = google_iam_workload_identity_pool.pool.id
}

output "workload_identity_pool_provider_id" {
  description = "ID of the created Workload Identity Provider"
  value       = google_iam_workload_identity_pool_provider.provider.id
}

output "workload_identity_provider_name" {
  description = "Full name of the Workload Identity Provider"
  value       = google_iam_workload_identity_pool_provider.provider.name
}

output "service_account_id" {
  description = "ID of the created service account"
  value       = google_service_account.yugabyte_sa.id
} 