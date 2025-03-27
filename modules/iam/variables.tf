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

variable "allowed_audience" {
  description = "Allowed audience for the OIDC provider"
  type        = string
  default     = "https://iam.googleapis.com/projects"
}

variable "service_account_id" {
  description = "ID for the YugabyteDB service account"
  type        = string
  default     = "yugabyte-sa"
  
  validation {
    condition     = can(regex("^[a-z][-a-z0-9]{5,29}$", var.service_account_id))
    error_message = "The service account ID must be 6-30 characters long, contain lowercase letters, numbers, and hyphens, and start with a letter."
  }
}

variable "repo_name" {
  description = "Repository name for Workload Identity Federation"
  type        = string
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
} 