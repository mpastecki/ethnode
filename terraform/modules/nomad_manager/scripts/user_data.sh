#!/bin/bash

###############################################################

set -ex -o pipefail

###############################################################

if ! sudo -n whoami; then
    >&2 echo "This script needs sudo"
    exit 1
fi

###############################################################

export DEBIAN_FRONTEND=noninteractive #zero interaction while installing or upgrading the system via apt. It accepts the default answer for all questions
export BASHOPTS # copy options to subshells

###############################################################

sudo -n bash <<EOF
apt-get update
apt-get dist-upgrade -y
apt-get autoremove -y
apt-get clean -y
EOF

###############################################################

sudo -n apt-get install -y curl jq software-properties-common gpg python3 # dependencies
sudo -n apt-get install -y atop htop iftop iotop net-tools tmux fish emacs # handy

###############################################################

chsh -s /usr/bin/fish ubuntu
chsh -s /usr/bin/fish root

###############################################################

### Nomad Development Mode Installation

### Storage preparation

# Create the mount point if it doesn't exist
sudo mkdir -p /opt/nomad

# Create an XFS file system on the device
sudo mkfs.xfs /dev/nvme1n1

# Add an entry to /etc/fstab to mount the volume at boot
echo '/dev/nvme1n1 /opt/nomad xfs defaults 0 2' | sudo tee -a /etc/fstab

# Mount the volume
sudo mount -a

###

sudo -n apt-get install -y wget gpg coreutils
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update
sudo -n apt-get install -y nomad

sudo cat << EOF > /etc/nomad.d/nomad.hcl
data_dir  = "/opt/nomad/data"

bind_addr = "0.0.0.0" # the default

server {
  enabled          = true
  bootstrap_expect = 1
}

client {
  enabled       = true
}

plugin "raw_exec" {
  config {
    enabled = true
  }
}
EOF

sudo systemctl enable nomad
sudo systemctl start nomad

###############################################################

### Ethereum Node Installation

sudo -n bash <<EOF
add-apt-repository ppa:ethereum/ethereum
apt-get update
apt-get install ethereum -y
EOF

# sudo cat << EOF > /lib/systemd/system/geth.service
# [Unit]

# Description=Geth Full Node
# After=network-online.target
# Wants=network-online.target

# [Service]

# WorkingDirectory=/home/ubuntu
# User=ubuntu
# ExecStart=/usr/bin/geth --authrpc.addr localhost --authrpc.port 8551 --authrpc.vhosts localhost --authrpc.jwtsecret /tmp/jwtsecret --syncmode snap --http --http.api personal,eth,net,web3,txpool --http.corsdomain *
# Restart=always
# RestartSec=5s

# [Install]
# WantedBy=multi-user.target
# EOF

# sudo systemctl enable geth
# sudo systemctl start geth

wget https://github.com/sigp/lighthouse/releases/download/v4.1.0/lighthouse-v4.1.0-x86_64-unknown-linux-gnu.tar.gz
tar zxvf lighthouse-v4.1.0-x86_64-unknown-linux-gnu.tar.gz
sudo mv lighthouse /usr/local/bin/

# sudo cat << EOF > /lib/systemd/system/lighthouse.service
# [Unit]

# Description=Lighthouse consensus client
# After=network-online.target
# Wants=network-online.target

# [Service]

# WorkingDirectory=/home/ubuntu
# User=ubuntu
# ExecStart=/usr/local/bin/lighthouse bn --network mainnet --execution-endpoint http://localhost:8551 --execution-jwt /tmp/jwtsecret --checkpoint-sync-url https://mainnet.checkpoint.sigp.io --disable-deposit-contract-sync
# Restart=always
# RestartSec=5s

# [Install]
# WantedBy=multi-user.target
# EOF

# sudo systemctl enable lighthouse
# sudo systemctl start lighthouse

###############################################################

sudo -n touch /root/.init-complete
exit 0 # explicit exit code