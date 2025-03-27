/**
 * Variables for YugabyteDB on GCP deployment
 */

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region for deployment"
  type        = string
  default     = "us-west1"
}

variable "cluster_name" {
  description = "Name of the YugabyteDB cluster"
  type        = string
  default     = "yugabyte-cluster"
}

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "yb-"
}

variable "node_count" {
  description = "Number of YugabyteDB nodes"
  type        = number
  default     = 3
  
  validation {
    condition     = var.node_count >= 3
    error_message = "Node count must be at least 3 for a production YugabyteDB deployment."
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

variable "yb_version" {
  description = "YugabyteDB version"
  type        = string
  default     = "2024.2.2.1"
}

variable "ssh_user" {
  description = "SSH user for the instances"
  type        = string
  default     = "centos"
}

variable "ssh_public_key" {
  description = "Path to SSH public key"
  type        = string
}

variable "ssh_private_key" {
  description = "Path to SSH private key"
  type        = string
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

variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "allowed_ssh_ranges" {
  description = "List of CIDR blocks allowed to connect via SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Note: For production, restrict this to specific IPs
}

variable "allowed_db_ranges" {
  description = "List of CIDR blocks allowed to connect to the database"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Note: For production, restrict this to specific IPs
}

variable "repo_name" {
  description = "Repository name for Workload Identity Federation"
  type        = string
  default     = "organization/repository"
}

# Security related variables
variable "enable_disk_encryption" {
  description = "Whether to enable disk encryption using Google KMS"
  type        = bool
  default     = false
}

variable "enable_vpc_flow_logs" {
  description = "Whether to enable VPC flow logs for enhanced security monitoring"
  type        = bool
  default     = true
}

variable "restrict_egress_traffic" {
  description = "Whether to restrict egress traffic to essential services only"
  type        = bool
  default     = false
}

variable "create_bastion_host" {
  description = "Whether to create a bastion host for secure SSH access"
  type        = bool
  default     = false
}

variable "enable_monitoring" {
  description = "Whether to enable cloud monitoring for YugabyteDB instances"
  type        = bool
  default     = true
}

variable "enable_backup" {
  description = "Whether to enable automated backups"
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "workload_identity_audience" {
  description = "Allowed audience for the OIDC provider"
  type        = string
  default     = "https://iam.googleapis.com/projects"
}

# Legacy variables for compatibility
variable "vpc_network" {
  description = "[DEPRECATED] Use modules/vpc instead"
  type        = string
  default     = "default"
}

variable "vpc_firewall" {
  description = "[DEPRECATED] Use modules/vpc instead"
  type        = string
  default     = "default"
}

variable "allowed_ips" {
  description = "[DEPRECATED] Use allowed_ssh_ranges and allowed_db_ranges instead"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "use_public_ip_for_ssh" {
  description = "[DEPRECATED] Use use_public_ip instead"
  type        = string
  default     = "true"
}
