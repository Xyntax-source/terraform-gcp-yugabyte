/**
 * Variables for IAM module
 */

variable "workload_identity_pool_id" {
  description = "ID for the Workload Identity Pool"
  type        = string
  default     = "yugabyte-pool"
}

variable "workload_identity_provider_id" {
  description = "ID for the Workload Identity Provider"
  type        = string
  default     = "yugabyte-provider"
}

variable "oidc_issuer_uri" {
  description = "URI for the OIDC issuer (e.g. GitHub's OIDC provider)"
  type        = string
  default     = "https://token.actions.githubusercontent.com"
}

variable "service_account_id" {
  description = "ID for the YugabyteDB service account"
  type        = string
  default     = "yugabyte-sa"
}

variable "repo_name" {
  description = "Repository name for Workload Identity Federation"
  type        = string
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
} 