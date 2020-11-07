#! /bin/bash

# For symbol-bootstrap-0.2.0
# Setup on GCP(GCE)
# Thank you 44uk !
# Reference URL 1: https://nemlog.nem.social/blog/49345
# Reference URL 2: https://github.com/44uk/symbol-testnet-node-running-hands-on

# Execute as root
sudo su

# Create Swap
fallocate -l 8G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

# Install Node.js and npm
curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
apt-get install -y nodejs
npm install -g npm@latest

# Install Symbol Bootstrap v0.2.0
npm install -g symbol-bootstrap@0.2.0

# Update packages
apt-get update -y && apt-get upgrade -y

# Install Docker
apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
apt-key fingerprint 0EBFCD88
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update -y && apt-get install -y docker-ce docker-ce-cli containerd.io

# Install Docker Compose
curl -L https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Docker Container Log File
echo '{"log-driver":"journald","log-opts":{"tag":"docker/{{.ImageName}}/{{.Name}}"}}' > /etc/docker/daemon.json
systemctl restart docker

# Create working directory
mkdir -p /opt/symbol-bootstrap
cd /opt/symbol-bootstrap

# Create custom setting yml file...At least, Edit host and friendlyName properly.
cat << _EOS_ >> my-preset.yml
nodes:
    -
        host: symbol-testnet-node.next-web-technology.com
        friendlyName: symbol-testnet-node.next-web-technology.com
gateways:
    -
        throttlingBurst: 80
        throttlingRate: 40
_EOS_

# Create setting files from custom setting yml file
symbol-bootstrap config -p testnet -a dual -c my-preset.yml

# Create docker-compose.yml
symbol-bootstrap compose

# Modify Bug
sed -i.bak '/set -e/d' target/docker/mongo/mongors.sh

# Start Symbol Bootstrap
symbol-bootstrap run -d

# Add Symbol Bootstrap to Service
cat << _EOS_ >> /etc/systemd/system/symbol-platform.service
[Unit]
Description=Symbol Platform Node Daemon
After=docker.service
[Service]
Type=simple
WorkingDirectory=/opt/symbol-bootstrap
ExecStartPre=/usr/bin/symbol-bootstrap stop
ExecStartPre=-/bin/rm target/nodes/api-node/data/server.lock
ExecStartPre=-/bin/rm target/nodes/api-node/data/broker.lock
ExecStart=/usr/bin/symbol-bootstrap run
ExecStop=/usr/bin/symbol-bootstrap stop
TimeoutStartSec=180
TimeoutStopSec=120
Restart=on-failure
RestartSec=60
PrivateTmp=true
[Install]
WantedBy=default.target
_EOS_

# Enable SSL with https-portal
cat << __EOD__ > https-portal.part.yml
    https-portal:
        container_name: https-portal
        image: steveltn/https-portal:1
        ports:
            - "80:80"
            - "3001:443"
        volumes:
            - ./ssl-certs:/var/lib/https-portal
        environment:
            WEBSOCKET: 'true'
            STAGE: production
            DOMAINS: 'symbol-testnet-node.next-web-technology.com -> http://rest-gateway:3000'
        depends_on:
            - rest-gateway
__EOD__
sed -i -e "$(grep -n services: target/docker/docker-compose.yml | cut -d: -f1)r https-portal.part.yml" target/docker/docker-compose.yml

# Reload Service Settings and Enable Service
systemctl daemon-reload
systemctl enable symbol-platform

# Restart Service
systemctl restart symbol-platform

# Install Cloud Monitoring Agent https://cloud.google.com/monitoring/agent/installation#agent-install-debian-ubuntu
curl -sSO https://dl.google.com/cloudagents/add-monitoring-agent-repo.sh
bash add-monitoring-agent-repo.sh
apt-get update -y
apt-get install stackdriver-agent -y
service stackdriver-agent start
