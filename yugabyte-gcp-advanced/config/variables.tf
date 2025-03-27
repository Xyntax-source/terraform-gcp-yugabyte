variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-west1"
}

variable "subnet_cidr" {
  description = "CIDR range for the subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "allowed_ips" {
  description = "List of IP addresses or CIDR ranges that are allowed to access the YugabyteDB cluster"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "github_repository" {
  description = "GitHub repository in format 'owner/repo'"
  type        = string
}

variable "notification_channels" {
  description = "List of notification channel IDs for alerts"
  type        = list(string)
}

variable "cluster_name" {
  description = "Name of the YugabyteDB cluster"
  type        = string
}

variable "node_count" {
  description = "Number of nodes in the cluster"
  type        = string
  default     = "3"
}

variable "replication_factor" {
  description = "Replication factor for the cluster"
  type        = string
  default     = "3"
}

variable "ssh_user" {
  description = "SSH user for instance access"
  type        = string
}

variable "ssh_private_key" {
  description = "Path to SSH private key"
  type        = string
}

variable "ssh_public_key" {
  description = "Path to SSH public key"
  type        = string
}

variable "node_type" {
  description = "GCP machine type"
  type        = string
  default     = "n1-standard-4"
}

variable "disk_size" {
  description = "Disk size in GB"
  type        = string
  default     = "100"
} 