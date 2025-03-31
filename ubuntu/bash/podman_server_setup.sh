#!/usr/bin/env bash

sudo apt -y install podman
sudo apt -y install podman-docker

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

podman compose version
