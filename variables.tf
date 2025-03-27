variable "cluster_name" {
  description = "The name for the cluster (universe) being created."
  type        = string
}
variable "use_public_ip_for_ssh" {
  description = "Flag to control use of public or private ips for ssh."
  default = "true"
  type = string
}
variable "replication_factor" {
  description = "The replication factor for the universe."
  default     = 3
  type        = string
}
variable "node_count" {
  description = "The number of nodes to create YugaByte Db Cluter"
  default     = 3
  type        = string

  validation {
    condition     = tonumber(var.node_count) >= 3
    error_message = "The node_count must be at least 3 for a production cluster."
  }
}
variable "vpc_network" {
  description = "VPC network to deploy YugaByte DB"
  default     = "default"
  type        = string
}
variable "vpc_firewall" {
  description = "Firewall used by the YugaByte Node"
  default     = "default"
  type        = string
}
variable "ssh_private_key" {
  description = "The private key to use when connecting to the instances."
  type        = string
}
variable "ssh_public_key" {
  description = "SSH public key to be use when creating the instances."
  type        = string
}
variable "ssh_user" {
  description = "User name to ssh YugaByte Node to configure cluster"
  type        = string
}
variable "node_type" {
  description = "Type of Node to be used for YugaByte DB node "
  default     = "n1-standard-4"
  type        = string
}
variable "yb_edition" {
  description = "The edition of YugaByteDB to install"
  default     = "ce"
  type        = string
}

variable "yb_download_url" {
  description = "The download location of the YugaByteDB edition"
  default     = "https://downloads.yugabyte.com"
  type        = string
}

variable "yb_version" {
  description = "The version number of YugaByteDB to install"
  default     = "2024.2.2.1"
  type        = string
}

variable "region_name" {
  description = "Region name for GCP"
  default     = "us-west1"
  type        = string
}
variable "disk_size" {
  description = "Disk size for YugaByte DB nodes"
  default     = "50"
  type        = string

  validation {
    condition     = tonumber(var.disk_size) >= 50
    error_message = "The disk_size must be at least 50GB for a production cluster."
  }
}
variable "prefix" {
  description = "Prefix prepended to all resources created."
  default     = "yugabyte-"
  type        = string
}

variable "allowed_ips" {
  description = "List of IP addresses or CIDR ranges that are allowed to access the YugabyteDB cluster"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
