/**
 * Variables for YugabyteDB module
 */

variable "cluster_name" {
  description = "Name of the YugabyteDB cluster"
  type        = string
}

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "yugabyte-"
}

variable "region" {
  description = "GCP region for the YugabyteDB cluster"
  type        = string
}

variable "node_count" {
  description = "Number of nodes in the YugabyteDB cluster"
  type        = number
  default     = 3
  
  validation {
    condition     = var.node_count >= 3
    error_message = "YugabyteDB requires at least 3 nodes for production deployments."
  }
}

variable "node_type" {
  description = "GCP machine type for YugabyteDB nodes"
  type        = string
  default     = "n1-standard-4"
}

variable "disk_size" {
  description = "Boot disk size in GB for YugabyteDB nodes"
  type        = number
  default     = 50
  
  validation {
    condition     = var.disk_size >= 50
    error_message = "Boot disk size must be at least 50GB."
  }
}

variable "data_disk_size" {
  description = "Data disk size in GB for YugabyteDB storage"
  type        = number
  default     = 100
  
  validation {
    condition     = var.data_disk_size >= 100
    error_message = "Data disk size must be at least 100GB for production workloads."
  }
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_id" {
  description = "ID of the private subnet"
  type        = string
}

variable "service_account_email" {
  description = "Email of the service account"
  type        = string
}

variable "use_public_ip" {
  description = "Whether to use public IP for YugabyteDB nodes"
  type        = bool
  default     = false
}

variable "use_preemptible_instances" {
  description = "Whether to use preemptible instances for YugabyteDB nodes (not recommended for production)"
  type        = bool
  default     = false
}

variable "ssh_user" {
  description = "SSH user for YugabyteDB nodes"
  type        = string
  default     = "centos"
}

variable "ssh_public_key" {
  description = "Path to SSH public key"
  type        = string
}

variable "yb_version" {
  description = "YugabyteDB version"
  type        = string
  default     = "2024.2.2.1"
}

variable "replication_factor" {
  description = "Replication factor for YugabyteDB"
  type        = number
  default     = 3
  
  validation {
    condition     = contains([3, 5, 7], var.replication_factor)
    error_message = "Replication factor must be one of [3, 5, 7] for optimal availability."
  }
}

variable "script_bucket" {
  description = "GCS bucket to store startup scripts (no longer required but kept for backward compatibility)"
  type        = string
  default     = ""
}

variable "kms_key_self_link" {
  description = "Self link of the KMS key used for disk encryption"
  type        = string
  default     = ""
}

variable "enable_monitoring" {
  description = "Whether to enable cloud monitoring for YugabyteDB instances"
  type        = bool
  default     = true
}

variable "enable_backup" {
  description = "Whether to enable automated backups"
  type        = bool
  default     = true
}

variable "backup_schedule" {
  description = "Cron schedule for automated backups (if enabled)"
  type        = string
  default     = "0 2 * * *"  # Daily at 2 AM
} 