terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  # Replace with your service account key file path
  credentials = file("service-account-key.json")
  # Replace with your GCP project ID
  project     = "your-project-id"
}

module "yugabyte-db-cluster" {
  source = "github.com/YugaByte/terraform-gcp-yugabyte.git"

  # Cluster Configuration
  cluster_name = "my-yugabyte-cluster"
  node_count   = "3"
  replication_factor = "3"

  # Network Configuration
  region_name = "us-west1"  # Change this to your preferred region
  vpc_network = "default"
  allowed_ips = ["0.0.0.0/0"]  # Change this to your IP address for security

  # SSH Configuration
  ssh_user = "centos"
  ssh_private_key = "~/.ssh/id_rsa"  # Path to your private key
  ssh_public_key  = "~/.ssh/id_rsa.pub"  # Path to your public key

  # Resource Configuration
  node_type = "n1-standard-4"
  disk_size = "100"  # GB
} 