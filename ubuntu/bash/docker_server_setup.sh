#!/bin/sh



###########################################################
# Install and Setup Docker
###########################################################
# uninstall any perviously installed docker packages
sudo apt-get remove docker docker-engine docker.io

# install docker using convenience install script from docker.com
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

sudo groupadd docker
sudo usermod -aG docker $USER

# set timeouts for start up and stopping docker service
DCK_SRV=/lib/systemd/system/docker.service
sudo grep -q '^TimeoutStopSec' $DCK_SRV && sudo sed -i 's/^TimeoutStopSec.*/TimeoutStopSec=45/' $DCK_SRV || sudo sed -i 's/TimeoutSec.*/TimeoutSec=300'"\n"'TimeoutStopSec=45/' $DCK_SRV

sudo systemctl enable docker
sudo systemctl start docker

###########################################################
# install docker compose cli plugin
###########################################################
sudo apt install -y jq
DOCKER_COMPOSE_VERSION=$(curl --silent https://api.github.com/repos/docker/compose/releases/latest | jq .name -r)
DOCKER_CLI_PLUGIN_PATH=/usr/local/lib/docker/cli-plugins
sudo mkdir -p $DOCKER_CLI_PLUGIN_PATH
sudo curl -L "https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o $DOCKER_CLI_PLUGIN_PATH/docker-compose
sudo chmod +x $DOCKER_CLI_PLUGIN_PATH/docker-compose

# docker compose is now a built in command but you can
# uncomment the line below to setup docker-compose command 
sudo ln -s  $DOCKER_CLI_PLUGIN_PATH/docker-compose /usr/local/bin/docker-compose

###########################################################
# disable-hugepages.service
###########################################################

sudo tee -a /etc/systemd/system/disable-hugepages.service >/dev/null <<'EOF'
[Unit]
Description="Disable Transparent Hugepage"
Before=docker.service      

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'echo never > /sys/kernel/mm/transparent_hugepage/enabled'
ExecStart=/bin/bash -c 'echo never > /sys/kernel/mm/transparent_hugepage/defrag'

[Install]
RequiredBy=docker.service
EOF

sudo systemctl daemon-reload
sudo systemctl enable disable-hugepages.service
sudo systemctl start disable-hugepages.service

###########################################################
# setup users environment
###########################################################
    
tee -a ~/.bashrc >/dev/null <<'EOF'
alias dc='docker compose'
alias dps='docker ps --format="table {{.Names}}\t{{.ID}}\t{{.Image}}\t{{.RunningFor}}\t{{.State}}\t{{.Status}}"'
alias dpsp='docker ps --format="table {{.Names}}\t{{.ID}}\t{{.Image}}\t{{.RunningFor}}\t{{.State}}\t{{.Status}}\t{{.Ports}}"'
EOF

###########################################################
# setup logrotate and other system maintenance automations
###########################################################
sudo tee -a /etc/logrotate.d/docker-container >/dev/null <<'EOF'
/var/lib/docker/containers/*/*.log {
  rotate 15
  daily
  compress
  missingok
  delaycompress
  copytruncate
}
EOF

sudo tee -a /etc/cron.weekly/docker-prune >/dev/null <<'EOF'
#!/bin/bash

/usr/bin/docker system prune -f
EOF
sudo chmod +x /etc/cron.weekly/docker-prune

echo "Docker setup complete!"
