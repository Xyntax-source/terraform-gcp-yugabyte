# Terraform Module for YugabyteDB on Google Cloud Platform

This Terraform module deploys a production-ready YugabyteDB cluster on Google Cloud Platform (GCP) with Workload Identity Federation and Virtual Private Cloud (VPC). It provides a comprehensive solution for securely deploying and managing YugabyteDB in the cloud.

## Architecture

This module consists of three main components:

1. **VPC Module**: Creates a custom VPC with public and private subnets, NAT gateway, and appropriate firewall rules.
2. **IAM Module**: Sets up Workload Identity Federation for authentication and creates necessary service accounts and permissions.
3. **YugabyteDB Module**: Deploys YugabyteDB instances in a managed instance group with health checks and load balancing.

## Features

- **Secure Authentication**: Uses Workload Identity Federation instead of service account keys
- **Network Isolation**: Deploys YugabyteDB in private subnets with controlled access
- **High Availability**: Configurable replication factor and multi-zone deployment
- **Managed Instance Group**: Automatic instance management with health checks
- **Load Balancing**: Internal load balancer for YugabyteDB access
- **Modular Design**: Each component can be modified independently
- **Comprehensive Security**: Firewall rules, IAM permissions, and network isolation

## Prerequisites

1. **GCP Account and Project**
   - A GCP account with billing enabled
   - A GCP project created
   - Required APIs enabled:
     - Compute Engine API
     - Cloud Resource Manager API
     - IAM API
     - IAM Credentials API
     - Workload Identity Federation API

2. **Terraform**
   - Terraform v1.0.0 or later
   - Google Cloud Provider v4.0 or later

## Usage

```hcl
module "yugabyte_cluster" {
  source = "github.com/YugaByte/terraform-gcp-yugabyte.git"

  # Project Configuration
  project_id = "your-gcp-project-id"
  region     = "us-west1"
  
  # Cluster Configuration
  cluster_name       = "yugabyte-cluster"
  node_count         = 3
  replication_factor = 3
  
  # Network Configuration
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets    = ["10.0.10.0/24", "10.0.11.0/24"]
  allowed_ssh_ranges = ["YOUR_IP/32"]
  allowed_db_ranges  = ["YOUR_SUBNET/24"]
  
  # Workload Identity Federation
  repo_name = "your-organization/your-repository"
  
  # SSH Configuration
  ssh_user        = "centos"
  ssh_public_key  = "/path/to/public/key"
  ssh_private_key = "/path/to/private/key"
}
```

## Modules

### VPC Module

The VPC module creates a custom VPC with public and private subnets, NAT gateway, and firewall rules.

#### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vpc_name | Name of the VPC | string | - | yes |
| region | GCP region for the VPC | string | - | yes |
| public_subnets | List of public subnet CIDR blocks | list(string) | ["10.0.1.0/24", "10.0.2.0/24"] | no |
| private_subnets | List of private subnet CIDR blocks | list(string) | ["10.0.10.0/24", "10.0.11.0/24"] | no |
| allowed_ssh_ranges | List of CIDR blocks allowed to connect via SSH | list(string) | ["0.0.0.0/0"] | no |
| allowed_db_ranges | List of CIDR blocks allowed to connect to the database | list(string) | ["0.0.0.0/0"] | no |

#### Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the created VPC |
| vpc_name | Name of the created VPC |
| vpc_self_link | Self link of the created VPC |
| public_subnet_ids | IDs of the public subnets |
| private_subnet_ids | IDs of the private subnets |

### IAM Module

The IAM module sets up Workload Identity Federation and creates necessary service accounts and permissions.

#### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_id | GCP Project ID | string | - | yes |
| workload_identity_pool_id | ID for the Workload Identity Pool | string | "yugabyte-pool" | no |
| workload_identity_provider_id | ID for the Workload Identity Provider | string | "yugabyte-provider" | no |
| oidc_issuer_uri | URI for the OIDC issuer | string | "https://token.actions.githubusercontent.com" | no |
| service_account_id | ID for the YugabyteDB service account | string | "yugabyte-sa" | no |
| repo_name | Repository name for Workload Identity Federation | string | - | yes |

#### Outputs

| Name | Description |
|------|-------------|
| service_account_email | Email of the created service account |
| workload_identity_pool_id | ID of the created Workload Identity Pool |
| workload_identity_provider_name | Full name of the Workload Identity Provider |

### YugabyteDB Module

The YugabyteDB module deploys YugabyteDB instances in a managed instance group with health checks and load balancing.

#### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Name of the YugabyteDB cluster | string | - | yes |
| prefix | Prefix for resource names | string | "yugabyte-" | no |
| region | GCP region for the YugabyteDB cluster | string | - | yes |
| node_count | Number of nodes in the YugabyteDB cluster | number | 3 | no |
| node_type | GCP machine type for YugabyteDB nodes | string | "n1-standard-4" | no |
| disk_size | Disk size in GB for YugabyteDB nodes | number | 100 | no |
| vpc_id | ID of the VPC | string | - | yes |
| private_subnet_id | ID of the private subnet | string | - | yes |
| service_account_email | Email of the service account | string | - | yes |
| use_public_ip | Whether to use public IP for YugabyteDB nodes | bool | false | no |
| ssh_user | SSH user for YugabyteDB nodes | string | "centos" | no |
| ssh_public_key | Path to SSH public key | string | - | yes |
| yb_version | YugabyteDB version | string | "2024.2.2.1" | no |
| replication_factor | Replication factor for YugabyteDB | number | 3 | no |
| script_bucket | GCS bucket to store startup scripts | string | - | yes |

#### Outputs

| Name | Description |
|------|-------------|
| cluster_name | Name of the YugabyteDB cluster |
| instance_group | Instance group for YugabyteDB nodes |
| ysql_connection_string | YSQL connection string |
| ilb_ip | IP of the internal load balancer |
| region | Region of the YugabyteDB cluster |
| node_count | Number of nodes in the YugabyteDB cluster |

## Security Considerations

1. **Workload Identity Federation**
   - Use Workload Identity Federation instead of service account keys for enhanced security
   - Configure repository access properly to prevent unauthorized use

2. **Network Isolation**
   - YugabyteDB instances are deployed in private subnets
   - NAT gateway provides outbound internet access
   - Firewall rules restrict inbound traffic

3. **Firewall Rules**
   - Restrict SSH access to specific IP ranges
   - Limit database access to authorized networks

4. **IAM Permissions**
   - Service account has minimal required permissions
   - Use principle of least privilege for all IAM roles

## Monitoring and Maintenance

1. **Health Checks**
   - Automatic health checks for YugabyteDB instances
   - Managed instance group handles instance replacement

2. **Logging and Monitoring**
   - Enable logging for YugabyteDB instances
   - Set up alerts for health check failures

3. **Backups**
   - Implement regular backups using YugabyteDB's built-in tools
   - Store backups in a separate GCS bucket

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the terms specified in the LICENSE file.
