variable "vpc_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
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