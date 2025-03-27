# Terraform Module for YugabyteDB on Google Cloud Platform

This Terraform module deploys a production-ready YugabyteDB cluster on Google Cloud Platform (GCP). It handles the complete setup including compute instances, networking, security, and cluster configuration.

## Features

- Deploys a distributed YugabyteDB cluster on GCP
- Configurable number of nodes and replication factor
- Automatic setup of firewall rules and security groups
- Built-in health checks and monitoring
- Support for both public and private IP access
- Automatic cluster initialization and configuration
- Comprehensive outputs for monitoring and management

## Prerequisites

1. **GCP Account and Project**
   - A GCP account with billing enabled
   - A GCP project created
   - Required APIs enabled:
     - Compute Engine API
     - Cloud Resource Manager API
     - IAM API

2. **GCP Credentials**
   - Service account with appropriate permissions
   - JSON key file for authentication
   - Required IAM roles:
     - `roles/compute.instanceAdmin.v1`
     - `roles/compute.networkAdmin`
     - `roles/iam.serviceAccountUser`

3. **Terraform**
   - Terraform v0.13 or later
   - Google Cloud Provider v4.0 or later

## Quick Start

1. **Initialize Terraform**
   ```bash
   terraform init
   ```

2. **Create a Terraform Configuration**
   Create a file named `main.tf` with the following content:
   ```hcl
   provider "google" {
     credentials = file("path/to/your/service-account-key.json")
     project     = "your-project-id"
   }

   module "yugabyte-db-cluster" {
     source = "github.com/YugaByte/terraform-gcp-yugabyte.git"

     # Cluster Configuration
     cluster_name = "my-yugabyte-cluster"
     node_count   = "3"
     replication_factor = "3"

     # Network Configuration
     region_name = "us-west1"
     vpc_network = "default"
     allowed_ips = ["YOUR_IP/32"]  # Restrict access to your IP

     # SSH Configuration
     ssh_user = "centos"
     ssh_private_key = "path/to/private/key"
     ssh_public_key  = "path/to/public/key"

     # Resource Configuration
     node_type = "n1-standard-4"
     disk_size = "100"  # GB
   }
   ```

3. **Plan and Apply**
   ```bash
   terraform plan
   terraform apply
   ```

## Input Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Name of the YugabyteDB cluster | string | - | yes |
| node_count | Number of nodes in the cluster | string | "3" | no |
| replication_factor | Replication factor for the cluster | string | "3" | no |
| region_name | GCP region to deploy the cluster | string | "us-west1" | no |
| vpc_network | VPC network name | string | "default" | no |
| allowed_ips | List of allowed IP addresses/CIDR ranges | list(string) | ["0.0.0.0/0"] | no |
| node_type | GCP machine type | string | "n1-standard-4" | no |
| disk_size | Disk size in GB | string | "50" | no |
| ssh_user | SSH user for instance access | string | - | yes |
| ssh_private_key | Path to SSH private key | string | - | yes |
| ssh_public_key | Path to SSH public key | string | - | yes |
| yb_version | YugabyteDB version to install | string | "2024.2.2.1" | no |
| prefix | Prefix for resource names | string | "yugabyte-" | no |

## Outputs

| Name | Description |
|------|-------------|
| ui | YugabyteDB UI URL |
| cluster_info | Information about the deployed cluster |
| node_ips | List of all node IPs (public and private) |
| connection_strings | Connection strings for different interfaces (YSQL, YCQL, YEDIS, JDBC) |

## Security Considerations

1. **Network Security**
   - By default, the cluster is accessible from all IPs (0.0.0.0/0)
   - Use the `allowed_ips` variable to restrict access to specific IP ranges
   - Consider using private IPs for internal communication

2. **SSH Access**
   - SSH access is required for cluster management
   - Use strong SSH keys and restrict access to trusted users
   - Consider using SSH bastion hosts for additional security

3. **Firewall Rules**
   - The module creates necessary firewall rules for:
     - YugabyteDB ports (9000, 7000, 6379, 9042, 5433)
     - SSH access (port 22)
     - Intra-cluster communication (ports 7100, 9100)

## Best Practices

1. **Resource Sizing**
   - Minimum 3 nodes for production use
   - Minimum 50GB disk size per node
   - Use n1-standard-4 or larger machine types

2. **High Availability**
   - Deploy across multiple availability zones
   - Use appropriate replication factor (3 for production)
   - Regular backups and monitoring

3. **Cost Optimization**
   - Use appropriate machine types for your workload
   - Consider using preemptible instances for non-critical workloads
   - Monitor resource usage and adjust as needed

## Monitoring and Maintenance

1. **Accessing the Cluster**
   - YugabyteDB UI: http://<node-ip>:7000
   - YSQL: Use the provided connection string
   - YCQL: Use the provided connection string
   - YEDIS: Use the provided connection string

2. **Health Checks**
   - Monitor node status through the YugabyteDB UI
   - Check replication status
   - Monitor disk usage and performance metrics

3. **Backup and Recovery**
   - Regular backups are recommended
   - Use YugabyteDB's built-in backup features
   - Test recovery procedures regularly

## Troubleshooting

1. **Common Issues**
   - SSH connection failures: Check firewall rules and SSH keys
   - Node startup issues: Check logs in /var/log/yugabyte
   - Cluster initialization failures: Check create_universe.sh logs

2. **Logs and Diagnostics**
   - YugabyteDB logs: /var/log/yugabyte
   - System logs: /var/log/syslog
   - Terraform logs: Check terraform.log

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the terms specified in the LICENSE file.
