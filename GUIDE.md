# Step-by-Step Guide for Using the YugabyteDB on GCP Terraform Module

This guide walks you through the process of deploying YugabyteDB on Google Cloud Platform (GCP) using this Terraform module with Workload Identity Federation and a custom VPC.

## Prerequisites

Before you begin, make sure you have the following:

1. **GCP Account and Project**
   - A GCP account with billing enabled
   - A GCP project created and activated
   - Owner or Editor role on the GCP project

2. **Required Software**
   - [Terraform](https://www.terraform.io/downloads.html) (v1.0.0 or newer)
   - [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) (gcloud CLI)
   - [Git](https://git-scm.com/downloads)

3. **SSH Key Pair**
   - Generate an SSH key pair for accessing the YugabyteDB instances
   - Command: `ssh-keygen -t rsa -b 4096 -f ~/.ssh/yugabyte_key`

## Step 1: Set Up Your GCP Project

1. **Enable Required APIs**

   ```bash
   # Login to GCP
   gcloud auth login

   # Set your project ID
   gcloud config set project YOUR_PROJECT_ID

   # Enable required APIs
   gcloud services enable compute.googleapis.com \
                          cloudresourcemanager.googleapis.com \
                          iam.googleapis.com \
                          iamcredentials.googleapis.com \
                          workloadidentityfederation.googleapis.com \
                          storage.googleapis.com
   ```

2. **Create a GitHub OIDC Provider** (if using GitHub Actions for deployment)

   ```bash
   # Create a Workload Identity Pool
   gcloud iam workload-identity-pools create "github-pool" \
       --project="YOUR_PROJECT_ID" \
       --location="global" \
       --display-name="GitHub Actions Pool"

   # Create a Workload Identity Provider
   gcloud iam workload-identity-pools providers create-oidc "github-provider" \
       --project="YOUR_PROJECT_ID" \
       --location="global" \
       --workload-identity-pool="github-pool" \
       --display-name="GitHub Provider" \
       --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
       --issuer-uri="https://token.actions.githubusercontent.com"
   ```

## Step 2: Clone the Repository

```bash
git clone https://github.com/YugaByte/terraform-gcp-yugabyte.git
cd terraform-gcp-yugabyte
```

## Step 3: Configure Your Deployment

1. **Create a terraform.tfvars File**

   Create a file named `terraform.tfvars` with your specific configuration values:

   ```hcl
   # Project Configuration
   project_id = "your-gcp-project-id"
   region     = "us-west1"
   
   # Cluster Configuration
   cluster_name       = "yugabyte-cluster"
   node_count         = 3
   replication_factor = 3
   node_type          = "n1-standard-4"
   disk_size          = 100
   
   # Network Configuration
   public_subnets     = ["10.0.1.0/24", "10.0.2.0/24"]
   private_subnets    = ["10.0.10.0/24", "10.0.11.0/24"]
   allowed_ssh_ranges = ["YOUR_IP/32"]  # Replace with your IP
   allowed_db_ranges  = ["YOUR_SUBNET/24"]  # Replace with allowed IPs
   
   # Workload Identity Federation
   repo_name = "your-organization/your-repository"
   
   # SSH Configuration
   ssh_user        = "centos"
   ssh_public_key  = "~/.ssh/yugabyte_key.pub"
   ssh_private_key = "~/.ssh/yugabyte_key"
   ```

2. **Customize Additional Variables (Optional)**

   You can modify additional variables in `variables.tf` for further customization, such as:
   - YugabyteDB version
   - Prefix for resource names
   - Use of public IPs for instances

## Step 4: Initialize and Deploy

1. **Initialize Terraform**

   ```bash
   terraform init
   ```

2. **Validate Your Configuration**

   ```bash
   terraform validate
   ```

3. **Review the Deployment Plan**

   ```bash
   terraform plan
   ```

4. **Deploy the Infrastructure**

   ```bash
   terraform apply
   ```

   Type `yes` when prompted to approve the action.

5. **Deployment Time**

   The deployment process typically takes 5-10 minutes to complete. During this time, Terraform will:
   - Create the VPC and subnets
   - Set up Workload Identity Federation
   - Deploy YugabyteDB instances
   - Configure health checks and load balancing

## Step 5: Accessing Your YugabyteDB Cluster

1. **Get Cluster Information**

   After the deployment completes, Terraform will output information about your cluster:

   ```bash
   terraform output
   ```

2. **Connect to YugabyteDB**

   To connect using YSQL (PostgreSQL-compatible interface):

   ```bash
   # Get the connection string
   CONNECTION_STRING=$(terraform output -raw ysql_connection_string)
   
   # Install the PostgreSQL client if needed
   # Ubuntu: sudo apt-get install postgresql-client
   # CentOS: sudo yum install postgresql
   
   # Connect
   psql "$CONNECTION_STRING"
   ```

3. **SSH Access to Instances (if needed)**

   You may need to access instances directly for advanced configuration:

   ```bash
   # Get instance IP (use private IP with a bastion host or public IP if configured)
   INSTANCE_IP=$(gcloud compute instances list --filter="name~'yugabyte'" --format="value(networkInterfaces[0].accessConfigs[0].natIP)" | head -1)
   
   # SSH to instance
   ssh -i ~/.ssh/yugabyte_key centos@$INSTANCE_IP
   ```

## Step 6: Managing Your Cluster

1. **Scaling Up**

   To increase the number of nodes:

   ```bash
   # Update node_count in terraform.tfvars, then run:
   terraform apply
   ```

2. **Updating Configuration**

   Modify any other parameter in your `terraform.tfvars` file and apply the changes:

   ```bash
   terraform apply
   ```

3. **Monitoring**

   You can monitor your YugabyteDB cluster using:

   - GCP Console -> Compute Engine -> VM instances
   - Cloud Monitoring for metrics
   - Cloud Logging for logs

## Step 7: Backing Up Data

1. **Set up Regular Backups**

   Create a separate GCS bucket for backups:

   ```bash
   gsutil mb gs://your-yugabyte-backups
   ```

2. **Use YugabyteDB Backup Tools**

   SSH into one of your instances and use `ysql_dump` to create a backup:

   ```bash
   ssh -i ~/.ssh/yugabyte_key centos@$INSTANCE_IP
   
   # Run backup
   ysql_dump -h localhost -U yugabyte -d yugabyte > backup.sql
   
   # Upload to GCS
   gsutil cp backup.sql gs://your-yugabyte-backups/
   ```

## Step 8: Destroying the Infrastructure (When Needed)

When you no longer need the infrastructure, you can destroy it:

```bash
terraform destroy
```

Type `yes` when prompted to approve the action.

## Security Best Practices

When deploying YugabyteDB on GCP, it's important to follow these security best practices:

1. **Network Security**
   - **Restrict access**: Set `allowed_ssh_ranges` and `allowed_db_ranges` to specific trusted IP ranges
   - **Use a bastion host**: Enable `create_bastion_host = true` for secure SSH access
   - **Implement egress restrictions**: Set `restrict_egress_traffic = true` to control outbound traffic

2. **Data Encryption**
   - **Enable disk encryption**: Set `enable_disk_encryption = true` to encrypt all disks with KMS
   - **Use secure connections**: Always use TLS/SSL for connections to YugabyteDB

3. **Identity and Access Management**
   - **Use Workload Identity Federation**: Avoid service account keys
   - **Apply least privilege**: The module now uses custom roles with minimal permissions
   - **Monitor service account activity**: Audit logs are enabled by default

4. **Instance Security**
   - **Run as non-root**: YugabyteDB now runs as the `yugabyte` user
   - **Enable Shielded VM features**: Secure boot, vTPM, and integrity monitoring
   - **Implement log rotation**: Logs are properly managed and rotated

## Troubleshooting Common Issues

### Cluster Initialization Failures

If your cluster does not initialize properly:

1. **Check instance logs**:
   ```bash
   gcloud compute ssh INSTANCE_NAME --command="sudo cat /var/log/yugabyte-startup.log"
   ```

2. **Verify master nodes can communicate**:
   ```bash
   gcloud compute ssh INSTANCE_NAME --command="curl -s http://localhost:7000/status"
   ```

3. **Check network connectivity**:
   ```bash
   # From one instance to another
   gcloud compute ssh INSTANCE_NAME --command="telnet OTHER_INSTANCE_IP 7100"
   ```

### Connection Issues

If you cannot connect to the database:

1. **Verify firewall rules**:
   ```bash
   gcloud compute firewall-rules list --filter="name~'yugabyte'"
   ```

2. **Check internal load balancer status**:
   ```bash
   gcloud compute forwarding-rules describe FORWARDING_RULE_NAME
   ```

3. **Test database connectivity directly**:
   ```bash
   gcloud compute ssh INSTANCE_NAME --command="ysqlsh -h localhost"
   ```

### Performance Issues

If you encounter performance problems:

1. **Check instance metrics**:
   - Go to Cloud Monitoring and view CPU, memory, and disk metrics
   - Look for bottlenecks in disk I/O or network throughput

2. **Review YugabyteDB logs**:
   ```bash
   gcloud compute ssh INSTANCE_NAME --command="sudo cat /var/log/yugabyte/yb-master.INFO"
   gcloud compute ssh INSTANCE_NAME --command="sudo cat /var/log/yugabyte/yb-tserver.INFO"
   ```

3. **Consider scaling**:
   - Increase `node_count` for more capacity
   - Use a larger `node_type` for more resources per node
   - Increase `data_disk_size` for more storage

## Best Practices

1. **Security**
   - Restrict `allowed_ssh_ranges` and `allowed_db_ranges` to specific IPs
   - Use a bastion host for SSH access
   - Regularly rotate SSH keys

2. **High Availability**
   - Deploy across multiple zones by using 3 or more nodes
   - Set `replication_factor` to match your availability requirements
   - Implement regular backups

3. **Cost Optimization**
   - Choose appropriate machine types for your workload
   - Set alerts for unexpected resource usage
   - Consider preemptible instances for non-critical workloads

## Further Resources

- [YugabyteDB Documentation](https://docs.yugabyte.com/)
- [Terraform GCP Provider Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GCP Virtual Private Cloud Documentation](https://cloud.google.com/vpc/docs)
- [Workload Identity Federation Documentation](https://cloud.google.com/iam/docs/workload-identity-federation) 