#!/bin/bash
# install_and_run_interactsh.sh
# This script installs Docker on Ubuntu, pulls the Interactsh Docker image,
# and then prompts the user for a domain to run the Interactsh container.
# It maps UDP port 53 and host TCP port 8080 (container's port 80) to avoid conflicts with a live website.
#
# Usage: sudo ./install_and_run_interactsh.sh

set -euo pipefail

# Ensure the script is run as root.
if [[ $EUID -ne 0 ]]; then
  echo "Please run as root. For example: sudo $0"
  exit 1
fi

# -----------------------------
# Docker Installation Section
# -----------------------------
echo "Updating package list..."
apt-get update -y

echo "Installing prerequisites..."
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

echo "Adding Docker's official GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "Setting up the Docker stable repository..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "Updating package list again..."
apt-get update -y

echo "Installing Docker Engine, CLI, and containerd..."
apt-get install -y docker-ce docker-ce-cli containerd.io

echo "Verifying Docker installation by running the hello-world container..."
docker run --rm hello-world

echo "Docker installation completed successfully."

# -----------------------------
# Interactsh Setup Section
# -----------------------------
echo "Pulling the latest Interactsh Docker image..."
docker pull projectdiscovery/interactsh-server:latest
