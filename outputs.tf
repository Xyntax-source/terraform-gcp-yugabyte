/**
 * Outputs for YugabyteDB on GCP deployment
 */

# VPC Outputs
output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc.vpc_id
}

output "vpc_name" {
  description = "Name of the created VPC"
  value       = module.vpc.vpc_name
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

# IAM Outputs
output "service_account_email" {
  description = "Email of the service account"
  value       = module.iam.service_account_email
}

output "workload_identity_pool_id" {
  description = "ID of the Workload Identity Pool"
  value       = module.iam.workload_identity_pool_id
}

output "workload_identity_provider_name" {
  description = "Name of the Workload Identity Provider"
  value       = module.iam.workload_identity_provider_name
}

# YugabyteDB Outputs
output "ysql_connection_string" {
  description = "YSQL connection string"
  value       = module.yugabytedb.ysql_connection_string
}

output "yugabytedb_ilb_ip" {
  description = "IP of the YugabyteDB internal load balancer"
  value       = module.yugabytedb.ilb_ip
}

output "yugabytedb_cluster_name" {
  description = "Name of the YugabyteDB cluster"
  value       = module.yugabytedb.cluster_name
}

output "yugabytedb_node_count" {
  description = "Number of nodes in the YugabyteDB cluster"
  value       = module.yugabytedb.node_count
}

# Combined information for easy access
output "cluster_info" {
  description = "Combined information about the YugabyteDB cluster"
  value = {
    cluster_name       = module.yugabytedb.cluster_name
    connection_string  = module.yugabytedb.ysql_connection_string
    node_count         = module.yugabytedb.node_count
    region             = module.yugabytedb.region
    vpc_id             = module.vpc.vpc_id
    service_account    = module.iam.service_account_email
  }
}
