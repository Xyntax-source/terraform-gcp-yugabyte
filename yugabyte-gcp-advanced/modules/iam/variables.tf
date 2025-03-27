variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "service_account_id" {
  description = "ID for the YugabyteDB service account"
  type        = string
}

variable "workload_identity_pool_id" {
  description = "ID for the Workload Identity Pool"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository in format 'owner/repo'"
  type        = string
} 