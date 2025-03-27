terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# VPC Module
module "vpc" {
  source = "../modules/vpc"

  vpc_name     = "${var.project_id}-vpc"
  region       = var.region
  subnet_cidr  = var.subnet_cidr
  allowed_ips  = var.allowed_ips
}

# IAM Module with Workload Identity Federation
module "iam" {
  source = "../modules/iam"

  project_id              = var.project_id
  service_account_id      = "yugabyte-sa"
  workload_identity_pool_id = "github-pool"
  github_repository      = var.github_repository
}

# Monitoring Module
module "monitoring" {
  source = "../modules/monitoring"

  notification_channels = var.notification_channels
}

# YugabyteDB Module
module "yugabyte-db-cluster" {
  source = "github.com/YugaByte/terraform-gcp-yugabyte.git"

  # Cluster Configuration
  cluster_name = var.cluster_name
  node_count   = var.node_count
  replication_factor = var.replication_factor

  # Network Configuration
  region_name = var.region
  vpc_network = module.vpc.network_name
  allowed_ips = var.allowed_ips

  # SSH Configuration
  ssh_user = var.ssh_user
  ssh_private_key = var.ssh_private_key
  ssh_public_key  = var.ssh_public_key

  # Resource Configuration
  node_type = var.node_type
  disk_size = var.disk_size

  # Service Account
  service_account_email = module.iam.service_account_email
} 