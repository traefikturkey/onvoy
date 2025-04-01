#!/usr/bin/env bash

# curl -s "https://raw.githubusercontent.com/traefikturkey/onvoy/refs/heads/main/ubuntu/bash/podman_server_setup.sh?$(date +%s)" | /bin/bash -s | tee ~/podman_build.log

# update if not done recently 
if [ -z "$(find /var/lib/apt/lists -maxdepth 1 -mmin -60)" ]; then
  apt-get update
fi

sudo apt -y install podman podman-docker slirp4netns uidmap

if [ -e /usr/local/bin/docker-compose ]; then
  echo "docker-compose already installed!"
else
  # Use GitHub API to get the latest release information for docker/compose
  api_url="https://api.github.com/repos/docker/compose/releases/latest"

  # Fetch the JSON response from the GitHub API
  # Remove control characters 
  RELEASE_VERSION=$(curl -s "$api_url" | tr -d '[:cntrl:]' | jq -r '.tag_name')

  sudo curl -sL https://github.com/docker/compose/releases/download/${RELEASE_VERSION}/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
  sudo chmod 755 /usr/local/bin/docker-compose
fi

# disable warning messages
sudo sed -i 's/^#compose_warning_logs = true/compose_warning_logs = false/' /usr/share/containers/containers.conf
sudo touch /etc/containers/nodocker

# rootless cannot expose privileged port by default
sudo sysctl net.ipv4.ip_unprivileged_port_start=53
echo "net.ipv4.ip_unprivileged_port_start=53" | sudo tee --append /etc/sysctl.conf

sudo systemctl enable podman.socket
sudo systemctl start podman.socket

systemctl --user enable podman.socket
systemctl --user start podman.socket
systemctl --user status podman.socket

podman compose version
