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
}

variable "node_type" {
  description = "GCP machine type for YugabyteDB nodes"
  type        = string
  default     = "n1-standard-4"
}

variable "disk_size" {
  description = "Disk size in GB for YugabyteDB nodes"
  type        = number
  default     = 100
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
}

variable "script_bucket" {
  description = "GCS bucket to store startup scripts"
  type        = string
} 