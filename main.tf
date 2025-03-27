/**
 * Terraform configuration for YugabyteDB deployment on GCP
 * Using Workload Identity Federation and VPC
 */

terraform {
  required_version = ">= 1.0.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.70.0"  # Using a more specific version for better stability
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Create a KMS key for disk encryption (optional)
resource "google_kms_key_ring" "yugabyte_keyring" {
  count    = var.enable_disk_encryption ? 1 : 0
  name     = "${var.prefix}${var.cluster_name}-keyring"
  location = var.region
}

resource "google_kms_crypto_key" "yugabyte_key" {
  count    = var.enable_disk_encryption ? 1 : 0
  name     = "${var.prefix}${var.cluster_name}-key"
  key_ring = google_kms_key_ring.yugabyte_keyring[0].id
  
  # Auto-rotate the key every 90 days
  rotation_period = "7776000s"
  
  # Prevent accidental destruction
  lifecycle {
    prevent_destroy = true
  }
}

# Grant the service account access to use the KMS key
resource "google_kms_crypto_key_iam_binding" "crypto_key" {
  count         = var.enable_disk_encryption ? 1 : 0
  crypto_key_id = google_kms_crypto_key.yugabyte_key[0].id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members       = ["serviceAccount:${module.iam.service_account_email}"]
  
  depends_on    = [module.iam]
}

# Create a GCS bucket for scripts and backups
resource "google_storage_bucket" "yugabyte_bucket" {
  name     = "${var.project_id}-${var.prefix}-${var.cluster_name}"
  location = var.region
  
  # Enable versioning for better data protection
  versioning {
    enabled = true
  }
  
  # Enforce secure access
  uniform_bucket_level_access = true
  
  # Set secure lifecycle rules
  lifecycle_rule {
    condition {
      age = 30 # days
    }
    action {
      type = "Delete"
    }
  }
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"
  
  vpc_name           = "${var.prefix}${var.cluster_name}-vpc"
  region             = var.region
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  allowed_ssh_ranges = var.allowed_ssh_ranges
  allowed_db_ranges  = var.allowed_db_ranges
  
  # Enhanced security options
  use_network_tags   = true
  restrict_egress    = var.restrict_egress_traffic
  enable_flow_logs   = var.enable_vpc_flow_logs
  create_bastion_host = var.create_bastion_host
}

# IAM Module
module "iam" {
  source = "./modules/iam"
  
  project_id                   = var.project_id
  workload_identity_pool_id    = "${var.prefix}${var.cluster_name}-pool"
  workload_identity_provider_id = "${var.prefix}${var.cluster_name}-provider"
  service_account_id           = "${var.prefix}${var.cluster_name}-sa"
  repo_name                    = var.repo_name
  allowed_audience             = var.workload_identity_audience
}

# YugabyteDB Module
module "yugabytedb" {
  source = "./modules/yugabytedb"
  
  # Basic configuration
  cluster_name         = var.cluster_name
  prefix               = var.prefix
  region               = var.region
  node_count           = var.node_count
  node_type            = var.node_type
  
  # Disk configuration
  disk_size            = var.disk_size
  data_disk_size       = var.data_disk_size
  
  # Network configuration
  vpc_id               = module.vpc.vpc_id
  private_subnet_id    = module.vpc.private_subnet_ids[0]
  use_public_ip        = var.use_public_ip
  
  # Security configuration
  service_account_email = module.iam.service_account_email
  kms_key_self_link    = var.enable_disk_encryption ? google_kms_crypto_key.yugabyte_key[0].id : ""
  use_preemptible_instances = var.use_preemptible_instances
  
  # Access configuration
  ssh_user             = var.ssh_user
  ssh_public_key       = var.ssh_public_key
  
  # Database configuration
  yb_version           = var.yb_version
  replication_factor   = var.replication_factor
  
  # Additional features
  enable_monitoring    = var.enable_monitoring
  enable_backup        = var.enable_backup
  
  # Deprecated but kept for backwards compatibility
  script_bucket        = google_storage_bucket.yugabyte_bucket.name
  
  # Ensure dependencies are properly ordered
  depends_on = [
    module.vpc,
    module.iam,
    google_storage_bucket.yugabyte_bucket
  ]
} 