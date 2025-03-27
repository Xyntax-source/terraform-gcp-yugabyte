#!/bin/bash
# YugabyteDB startup script

set -e

# Install dependencies
yum update -y
yum install -y wget curl python3 python3-pip ntp jq util-linux

# Set up NTP
systemctl enable ntpd
systemctl start ntpd

# Create yugabyte user and group
groupadd -r yugabyte || true
useradd -r -g yugabyte -s /bin/bash -d /home/yugabyte -m yugabyte || true

# Prepare data disk
DATA_DISK_DEV=$(lsblk -o NAME,SERIAL | grep yugabyte-data | awk '{print $1}')
if [ -z "$DATA_DISK_DEV" ]; then
  echo "Data disk not found, checking for available disks..."
  # Find the first non-boot disk
  DATA_DISK_DEV=$(lsblk -o NAME,TYPE | grep disk | grep -v sda | head -1 | awk '{print $1}')
fi

if [ -n "$DATA_DISK_DEV" ]; then
  echo "Using disk /dev/$DATA_DISK_DEV for YugabyteDB data"
  # Format disk if needed
  if ! file -s /dev/$DATA_DISK_DEV | grep -q ext4; then
    echo "Formatting data disk..."
    mkfs.ext4 /dev/$DATA_DISK_DEV
  fi
  
  # Create mount point
  mkdir -p /mnt/data/disk1
  
  # Add to fstab
  if ! grep -q "/dev/$DATA_DISK_DEV" /etc/fstab; then
    echo "/dev/$DATA_DISK_DEV /mnt/data/disk1 ext4 defaults,nofail 0 2" >> /etc/fstab
  fi
  
  # Mount the disk
  mount /mnt/data/disk1 || mount -a
else
  echo "No data disk found, using boot disk for data"
  mkdir -p /mnt/data/disk1
fi

# Install YugabyteDB
YB_VERSION="${yb_version}"
wget -q https://downloads.yugabyte.com/releases/$YB_VERSION/yugabyte-$YB_VERSION-linux.tar.gz
tar -xf yugabyte-$YB_VERSION-linux.tar.gz
mv yugabyte-$YB_VERSION/ /opt/yugabyte
rm yugabyte-$YB_VERSION-linux.tar.gz

# Set proper permissions
chown -R yugabyte:yugabyte /opt/yugabyte /mnt/data

# Get instance metadata
INSTANCE_ID=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/id" -H "Metadata-Flavor: Google")
INSTANCE_NAME=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/name" -H "Metadata-Flavor: Google")
INSTANCE_ZONE=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/zone" -H "Metadata-Flavor: Google" | awk -F/ '{print $NF}')
PRIVATE_IP=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip" -H "Metadata-Flavor: Google")
PROJECT_ID=$(curl -s "http://metadata.google.internal/computeMetadata/v1/project/project-id" -H "Metadata-Flavor: Google")

# Get all instances in the instance group to build master addresses
CLUSTER_NAME="${cluster_name}"
INSTANCE_GROUP_NAME="${prefix}${cluster_name}-mig"
REGION="${region}"

# Discover other nodes via instance group membership
# This might take some time as instances are being created
# We'll retry for up to 5 minutes
MAX_RETRIES=30
RETRY_INTERVAL=10
RETRY_COUNT=0
MASTER_IPS=""

while [ -z "$MASTER_IPS" ] && [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  MASTER_IPS=$(gcloud compute instance-groups managed list-instances $INSTANCE_GROUP_NAME \
    --region=$REGION --project=$PROJECT_ID --format="json" | \
    jq -r '.[].instance' | xargs -I{} \
    gcloud compute instances describe {} --zone=$(echo {} | awk -F/ '{print $NF}') \
    --project=$PROJECT_ID --format="json" | \
    jq -r '.networkInterfaces[0].networkIP' | tr '\n' ',' | sed 's/,$//')
  
  if [ -z "$MASTER_IPS" ]; then
    echo "Waiting for other instances... Retry $RETRY_COUNT of $MAX_RETRIES"
    sleep $RETRY_INTERVAL
    RETRY_COUNT=$((RETRY_COUNT+1))
  fi
done

if [ -z "$MASTER_IPS" ]; then
  echo "Failed to discover other nodes. Using only local IP for master address."
  MASTER_IPS=$PRIVATE_IP
fi

# Append ports to master IPs
MASTER_ADDRESSES=$(echo $MASTER_IPS | sed 's/,/:7100,/g'):7100
echo "Master addresses: $MASTER_ADDRESSES"

# Configure YugabyteDB
cd /opt/yugabyte

# Configure flags for master
cat > master.conf <<EOF
--master_addresses=$MASTER_ADDRESSES
--fs_data_dirs=/mnt/data/disk1
--rpc_bind_addresses=$PRIVATE_IP:7100
--webserver_interface=$PRIVATE_IP
--placement_cloud=gcp
--placement_region=${region}
--placement_zone=$INSTANCE_ZONE
--use_private_ip=true
--replication_factor=${replication_factor}
--enable_ysql=true
EOF

# Configure flags for tserver
cat > tserver.conf <<EOF
--tserver_master_addrs=$MASTER_ADDRESSES
--fs_data_dirs=/mnt/data/disk1
--rpc_bind_addresses=$PRIVATE_IP:9100
--webserver_interface=$PRIVATE_IP
--placement_cloud=gcp
--placement_region=${region}
--placement_zone=$INSTANCE_ZONE
--use_private_ip=true
--memory_limit_hard_bytes=60%
EOF

# Create systemd services
cat > /etc/systemd/system/yugabyte-master.service <<EOF
[Unit]
Description=YugabyteDB Master
After=network.target

[Service]
User=yugabyte
Group=yugabyte
WorkingDirectory=/opt/yugabyte
ExecStart=/opt/yugabyte/bin/yb-master --flagfile=/opt/yugabyte/master.conf
Restart=always
TimeoutStartSec=300
LimitNOFILE=1048576
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/yugabyte-tserver.service <<EOF
[Unit]
Description=YugabyteDB TServer
After=network.target yugabyte-master.service
Requires=yugabyte-master.service

[Service]
User=yugabyte
Group=yugabyte
WorkingDirectory=/opt/yugabyte
ExecStart=/opt/yugabyte/bin/yb-tserver --flagfile=/opt/yugabyte/tserver.conf
Restart=always
TimeoutStartSec=300
LimitNOFILE=1048576
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF

# Create a log directory with proper permissions
mkdir -p /var/log/yugabyte
chown -R yugabyte:yugabyte /var/log/yugabyte

# Setup log rotation
cat > /etc/logrotate.d/yugabyte <<EOF
/var/log/yugabyte/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0640 yugabyte yugabyte
    sharedscripts
    postrotate
        systemctl reload yugabyte-master.service > /dev/null 2>/dev/null || true
        systemctl reload yugabyte-tserver.service > /dev/null 2>/dev/null || true
    endscript
}
EOF

# Enable and start services
systemctl daemon-reload
systemctl enable yugabyte-master
systemctl start yugabyte-master
sleep 10  # Give the master some time to start
systemctl enable yugabyte-tserver
systemctl start yugabyte-tserver

# Log completion
echo "YugabyteDB installation completed at $(date)" >> /var/log/yugabyte-startup.log

# Monitor startup progress - helps detect successful initialization
TIMEOUT=300
INTERVAL=10
ELAPSED=0

while [ $ELAPSED -lt $TIMEOUT ]; do
  # Check if masters are up
  MASTER_STATUS=$(curl -s http://$PRIVATE_IP:7000/status || echo "failed")
  
  # Check if tservers are up
  TSERVER_STATUS=$(curl -s http://$PRIVATE_IP:9000/status || echo "failed")
  
  if [[ $MASTER_STATUS != "failed" && $TSERVER_STATUS != "failed" ]]; then
    echo "YugabyteDB cluster successfully initialized at $(date)" >> /var/log/yugabyte-startup.log
    exit 0
  fi
  
  sleep $INTERVAL
  ELAPSED=$((ELAPSED + INTERVAL))
  echo "Waiting for YugabyteDB services to initialize... $ELAPSED/$TIMEOUT seconds elapsed" >> /var/log/yugabyte-startup.log
done

echo "WARNING: Startup monitoring timed out after $TIMEOUT seconds. Services may not be fully initialized." >> /var/log/yugabyte-startup.log 