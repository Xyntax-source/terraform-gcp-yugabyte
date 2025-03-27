#!/bin/bash
# YugabyteDB startup script

set -e

# Install dependencies
yum update -y
yum install -y wget curl python3 python3-pip ntp

# Set up NTP
systemctl enable ntpd
systemctl start ntpd

# Install YugabyteDB
YB_VERSION="${yb_version}"
wget -q https://downloads.yugabyte.com/releases/$YB_VERSION/yugabyte-$YB_VERSION-linux.tar.gz
tar -xf yugabyte-$YB_VERSION-linux.tar.gz
mv yugabyte-$YB_VERSION/ /opt/yugabyte
rm yugabyte-$YB_VERSION-linux.tar.gz

# Create data directory
mkdir -p /mnt/data/disk1

# Get instance metadata
INSTANCE_ID=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/id" -H "Metadata-Flavor: Google")
INSTANCE_NAME=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/name" -H "Metadata-Flavor: Google")
INSTANCE_ZONE=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/zone" -H "Metadata-Flavor: Google" | awk -F/ '{print $NF}')
PRIVATE_IP=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip" -H "Metadata-Flavor: Google")

# Configure YugabyteDB
cd /opt/yugabyte

# Configure flags for master
cat > master.conf <<EOF
--master_addresses=MASTER_ADDRESSES
--fs_data_dirs=/mnt/data/disk1
--rpc_bind_addresses=$PRIVATE_IP:7100
--webserver_interface=$PRIVATE_IP
--placement_cloud=gcp
--placement_region=${region}
--placement_zone=$INSTANCE_ZONE
EOF

# Configure flags for tserver
cat > tserver.conf <<EOF
--tserver_master_addrs=MASTER_ADDRESSES
--fs_data_dirs=/mnt/data/disk1
--rpc_bind_addresses=$PRIVATE_IP:9100
--webserver_interface=$PRIVATE_IP
--placement_cloud=gcp
--placement_region=${region}
--placement_zone=$INSTANCE_ZONE
--memory_limit_hard_bytes=60%
EOF

# Create systemd services
cat > /etc/systemd/system/yugabyte-master.service <<EOF
[Unit]
Description=YugabyteDB Master
After=network.target

[Service]
User=root
Group=root
WorkingDirectory=/opt/yugabyte
ExecStart=/opt/yugabyte/bin/yb-master --flagfile=/opt/yugabyte/master.conf
Restart=always
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/yugabyte-tserver.service <<EOF
[Unit]
Description=YugabyteDB TServer
After=network.target yugabyte-master.service
Requires=yugabyte-master.service

[Service]
User=root
Group=root
WorkingDirectory=/opt/yugabyte
ExecStart=/opt/yugabyte/bin/yb-tserver --flagfile=/opt/yugabyte/tserver.conf
Restart=always
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

# Join the cluster
# This will be handled by a separate script that runs after all instances are up

# Enable and start services
systemctl daemon-reload
systemctl enable yugabyte-master
systemctl enable yugabyte-tserver

# Log completion
echo "YugabyteDB installation completed at $(date)" >> /var/log/yugabyte-startup.log 