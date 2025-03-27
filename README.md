# Terraform Module for YugabyteDB on GCP

This repository contains a Terraform module for deploying YugabyteDB on Google Cloud Platform (GCP) with a focus on security, high availability, and operational excellence.

## Features

- **Secure Networking**:
  - VPC with public and private subnets
  - Private connectivity for YugabyteDB nodes
  - Redundant NAT gateways for high availability
  - Fine-grained firewall rules with network tags
  - Optional egress traffic restrictions

- **Strong Security**:
  - Workload Identity Federation for secure authentication
  - Minimal IAM permissions following principle of least privilege
  - Disk encryption with Google KMS
  - Shielded VMs with secure boot and integrity monitoring
  - VPC flow logs for enhanced network security monitoring
  - Option to create a bastion host for secure SSH access

- **High Availability**:
  - Nodes distributed across availability zones
  - Comprehensive health checks with auto-healing
  - Regional internal load balancer with session affinity
  - Controlled rollout policy for updates

- **Operational Excellence**:
  - Proper log rotation and management
  - Monitoring integration
  - Automated backups
  - Comprehensive startup monitoring

## Architecture

The module consists of three main components:

1. **VPC Module** (`./modules/vpc`): Creates the network infrastructure including VPC, subnets, NAT gateways, and firewall rules.
2. **IAM Module** (`./modules/iam`): Sets up Workload Identity Federation and necessary service accounts with minimal permissions.
3. **YugabyteDB Module** (`./modules/yugabytedb`): Deploys YugabyteDB nodes, load balancers, and health checks.

## Usage

```hcl
module "yugabytedb" {
  source = "github.com/yugabyte/terraform-gcp-yugabyte"

  # Project configuration
  project_id = "your-gcp-project-id"
  region     = "us-west1"

  # Cluster configuration
  cluster_name       = "yugabyte-cluster"
  node_count         = 3
  replication_factor = 3
  node_type          = "n1-standard-4"
  disk_size          = 50
  data_disk_size     = 100

  # Network configuration
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets    = ["10.0.10.0/24", "10.0.11.0/24"]
  allowed_ssh_ranges = ["YOUR_IP/32"]
  allowed_db_ranges  = ["YOUR_SUBNET/24"]

  # Workload Identity Federation
  repo_name = "your-organization/your-repository"

  # SSH configuration
  ssh_user       = "centos"
  ssh_public_key = "~/.ssh/yugabyte_key.pub"
  ssh_private_key = "~/.ssh/yugabyte_key"

  # Enhanced security options
  enable_disk_encryption  = true
  enable_vpc_flow_logs    = true
  restrict_egress_traffic = true
  create_bastion_host     = true
}
```

## Required Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| project_id | GCP Project ID | string | - |
| region | GCP region for deployment | string | - |
| ssh_public_key | Path to SSH public key | string | - |
| ssh_private_key | Path to SSH private key | string | - |
| repo_name | Repository name for Workload Identity Federation | string | - |

## Optional Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| cluster_name | Name of the YugabyteDB cluster | string | "yugabyte-cluster" |
| node_count | Number of YugabyteDB nodes | number | 3 |
| node_type | GCP machine type for YugabyteDB nodes | string | "n1-standard-4" |
| disk_size | Boot disk size in GB | number | 50 |
| data_disk_size | Data disk size in GB | number | 100 |
| replication_factor | YugabyteDB replication factor | number | 3 |
| yb_version | YugabyteDB version | string | "2024.2.2.1" |
| enable_disk_encryption | Whether to enable disk encryption | bool | false |
| enable_vpc_flow_logs | Whether to enable VPC flow logs | bool | true |
| restrict_egress_traffic | Whether to restrict egress traffic | bool | false |
| create_bastion_host | Whether to create a bastion host | bool | false |
| enable_monitoring | Whether to enable monitoring | bool | true |
| enable_backup | Whether to enable automated backups | bool | false |

## Outputs

| Name | Description |
|------|-------------|
| ysql_connection_string | YSQL connection string |
| yugabyte_ui_url | URL for the YugabyteDB admin UI |
| yugabytedb_ilb_ip | IP of the YugabyteDB internal load balancer |
| service_account_email | Email of the service account |
| vpc_id | ID of the created VPC |

## Security Best Practices

For a production deployment, consider the following security recommendations:

1. **Restrict IP Access**: 
   - Set `allowed_ssh_ranges` to specific trusted IP ranges
   - Set `allowed_db_ranges` to specific application subnets

2. **Use a Bastion Host**: 
   - Enable `create_bastion_host = true` for secure SSH access

3. **Enable Disk Encryption**: 
   - Set `enable_disk_encryption = true` to encrypt all disks with KMS

4. **Restrict Egress Traffic**: 
   - Set `restrict_egress_traffic = true` to control outbound traffic

5. **Enable Flow Logs**: 
   - Keep `enable_vpc_flow_logs = true` for security monitoring

## Getting Started

For detailed deployment instructions, refer to the [Step-by-Step Guide](GUIDE.md).

## License

Apache License 2.0

## Support

For support or questions, open an issue in this repository or contact YugabyteDB support.
