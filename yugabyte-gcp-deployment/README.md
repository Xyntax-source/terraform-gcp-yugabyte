# YugabyteDB GCP Deployment Guide

This guide will help you deploy YugabyteDB on Google Cloud Platform using Terraform.

## Prerequisites

1. **GCP Setup**
   - Create a GCP project if you haven't already
   - Enable the following APIs in your project:
     - Compute Engine API
     - Cloud Resource Manager API
     - IAM API
   - Create a service account and download the JSON key file

2. **Local Setup**
   - Install Terraform (v0.13 or later)
   - Install Google Cloud SDK
   - Generate SSH key pair if you don't have one:
     ```bash
     ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa
     ```

## Deployment Steps

1. **Configure GCP Credentials**
   - Place your service account JSON key file in this directory as `service-account-key.json`
   - Update the `project` value in `main.tf` with your GCP project ID

2. **Update Configuration**
   - Modify `main.tf` to set your preferred:
     - Region (`region_name`)
     - Cluster name (`cluster_name`)
     - Node count and type
     - Disk size
     - Allowed IPs (for security)

3. **Initialize Terraform**
   ```bash
   terraform init
   ```

4. **Review the Plan**
   ```bash
   terraform plan
   ```
   Review the changes that will be made to your GCP project.

5. **Apply the Configuration**
   ```bash
   terraform apply
   ```
   Type 'yes' when prompted to confirm the deployment.

6. **Access the Cluster**
   After deployment completes, you'll see outputs including:
   - YugabyteDB UI URL
   - Connection strings for YSQL, YCQL, and YEDIS
   - Node IPs

## Important Notes

1. **Costs**
   - This deployment will create:
     - 3 n1-standard-4 instances
     - 100GB disks per instance
     - Firewall rules
   - Estimated monthly cost: $300-400 (varies by region)

2. **Security**
   - Update `allowed_ips` in `main.tf` to restrict access
   - Keep your service account key secure
   - Use strong SSH keys

3. **Maintenance**
   - Monitor the cluster through the YugabyteDB UI
   - Regular backups are recommended
   - Keep track of resource usage

## Troubleshooting

If you encounter issues:

1. **SSH Connection Problems**
   - Verify your SSH keys are correctly configured
   - Check firewall rules in GCP console
   - Ensure your IP is in the allowed_ips list

2. **Cluster Initialization Issues**
   - Check the YugabyteDB logs: `/var/log/yugabyte`
   - Verify all required ports are open
   - Check node status in the YugabyteDB UI

3. **Resource Creation Failures**
   - Verify your GCP project has sufficient quota
   - Check service account permissions
   - Review Terraform logs

## Cleanup

To remove the deployment:
```bash
terraform destroy
```
Type 'yes' when prompted to confirm the removal.

## Support

For issues with:
- Terraform configuration: Check the [module documentation](../README.md)
- YugabyteDB: Visit [YugabyteDB documentation](https://docs.yugabyte.com)
- GCP: Visit [GCP documentation](https://cloud.google.com/docs) 