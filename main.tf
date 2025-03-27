/**
 * Terraform configuration for YugabyteDB deployment on GCP
 * Using Workload Identity Federation and VPC
 */

terraform {
  required_version = ">= 1.0.0"
  
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

# Create a GCS bucket for scripts
resource "google_storage_bucket" "scripts" {
  name     = "${var.project_id}-yugabyte-scripts"
  location = var.region
  uniform_bucket_level_access = true
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"
  
  vpc_name         = "${var.prefix}${var.cluster_name}-vpc"
  region           = var.region
  public_subnets   = var.public_subnets
  private_subnets  = var.private_subnets
  allowed_ssh_ranges = var.allowed_ssh_ranges
  allowed_db_ranges  = var.allowed_db_ranges
}

# IAM Module
module "iam" {
  source = "./modules/iam"
  
  project_id                   = var.project_id
  workload_identity_pool_id    = "${var.prefix}${var.cluster_name}-pool"
  workload_identity_provider_id = "${var.prefix}${var.cluster_name}-provider"
  service_account_id           = "${var.prefix}${var.cluster_name}-sa"
  repo_name                    = var.repo_name
}

# YugabyteDB Module
module "yugabytedb" {
  source = "./modules/yugabytedb"
  
  cluster_name         = var.cluster_name
  prefix               = var.prefix
  region               = var.region
  node_count           = var.node_count
  node_type            = var.node_type
  disk_size            = var.disk_size
  vpc_id               = module.vpc.vpc_id
  private_subnet_id    = module.vpc.private_subnet_ids[0]
  service_account_email = module.iam.service_account_email
  use_public_ip        = var.use_public_ip
  ssh_user             = var.ssh_user
  ssh_public_key       = var.ssh_public_key
  yb_version           = var.yb_version
  replication_factor   = var.replication_factor
  script_bucket        = google_storage_bucket.scripts.name
} 