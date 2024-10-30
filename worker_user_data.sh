#!/bin/bash
# Update packages and install curl
sudo apt-get update -y
sudo apt-get install -y curl

# Install k3s worker node
curl -sfL https://get.k3s.io | K3S_URL="https://${master_ip}:6443" K3S_TOKEN="$(cat /var/lib/rancher/k3s/server/node-token)" sh -
