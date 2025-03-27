/**
 * Variables for VPC module
 */

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "region" {
  description = "GCP region for the VPC"
  type        = string
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

variable "use_network_tags" {
  description = "Whether to use network tags for firewall rules instead of CIDR ranges"
  type        = bool
  default     = true
}

variable "restrict_egress" {
  description = "Whether to restrict egress traffic to essential services only"
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Whether to enable VPC flow logs for enhanced security monitoring"
  type        = bool
  default     = true
}

variable "create_bastion_host" {
  description = "Whether to create a bastion host for secure SSH access"
  type        = bool
  default     = false
}

variable "bastion_machine_type" {
  description = "Machine type for the bastion host"
  type        = string
  default     = "e2-micro"
}

variable "bastion_os_image" {
  description = "OS image for the bastion host"
  type        = string
  default     = "debian-cloud/debian-11"
} 