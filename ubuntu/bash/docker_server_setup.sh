#!/bin/sh

echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee --append /etc/sudoers.d/$USER

# quiet down the console
echo "3 4 1 3" | sudo tee /proc/sys/kernel/printk
echo "kernel.printk = 3 4 1 3" | sudo tee --append /etc/sysctl.conf

# Setting for redis to behave during background saves
sudo sysctl vm.overcommit_memory=1
echo "vm.overcommit_memory = 1" | sudo tee --append /etc/sysctl.conf

sudo sysctl net.core.somaxconn=1024
echo "net.core.somaxconn = 1024" | sudo tee --append /etc/sysctl.conf

# makde dockerized elasticsearch happy 
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count = 262144" | sudo tee --append /etc/sysctl.conf
sudo sysctl -w vm.swappiness=1
echo "vm.swappiness=1" | sudo tee --append /etc/sysctl.conf

# Set Timezone of server
# timedatectl list-timezones
# sudo timedatectl set-timezone America/New_York
sudo timedatectl set-timezone America/Los_Angeles
sudo timedatectl set-local-rtc 1 # 1=local 0=UTC
sudo timedatectl set-ntp true

# disable ip6
sudo sysctl net.ipv6.conf.all.disable_ipv6=1
sudo sysctl net.ipv6.conf.default.disable_ipv6=1
echo "net.ipv6.conf.all.disable_ipv6=1" | sudo tee --append /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6=1" | sudo tee --append /etc/sysctl.conf

# basic system administration packages
sudo apt update
sudo apt install -y \
    anacron \
    apt-transport-https \
    bwm-ng \
    ca-certificates \
    curl \
    dnsutils \
    git \
    gnupg \
    htop \
    iftop \
    iotop \
    logrotate \
    lsb-release \
    make \
    nano \
    bash-completion \
    net-tools \
    sysstat \
    software-properties-common \
    vnstat
    
sudo apt purge -y landscape-common

# Disable Ubuntu motd spam
sudo systemctl disable motd-news.timer
sudo sed -i 's/^ENABLED=.*/ENABLED=0/' /etc/default/motd-news
rm -f /etc/legal

# tone down the adware and login noise
# sudo chmod -x /etc/update-motd.d/50-motd-news # prevents motd-news.service from starting
sudo chmod -x \
    /etc/update-motd.d/10-help-text \
    /etc/update-motd.d/80-livepatch \
    /etc/update-motd.d/95-hwe-eol

# speed up boot times
# https://askubuntu.com/a/979493
# speed up booting by not letting networkd wait around for unconfigured interfaces
sudo systemctl disable systemd-networkd-wait-online.service
sudo systemctl mask systemd-networkd-wait-online.service

sudo mkdir -p /etc/systemd/system.conf.d/
sudo tee /etc/systemd/system.conf.d/timeoutstopsec.conf >/dev/null <<'EOF'
[Manager]
# default wait time for services to stop during shutdown/reboot
# before systemd will kill it and move on
DefaultTimeoutStopSec=10s
EOF

if [[ $(sudo lsmod | grep ipmi | wc -l) != 0 ]]; then
    echo "Installing IPMI and configuring systemd watchdog"
    sudo apt install openipmi ipmitool -y
    if [[ $(grep ipmi /etc/modules | wc -l) == 0 ]]; then
      echo "ipmi_watchdog" | sudo tee /etc/modules
    fi
   
sudo tee /etc/systemd/system.conf.d/watchdog.conf >/dev/null <<'EOF'
[Manager]
# configures /dev/watchdog for how long it should wait for a ping
RuntimeWatchdogSec==20s
# how long to wait for a clean reboot shutdown before doing a hardware reset
ShutdownWatchdogSec=180s
EOF
    # restart systemd
    sudo systemctl daemon-reexec
fi

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

# Fire and forget
export DEBIAN_FRONTEND=noninteractive
# https://askubuntu.com/a/1421221
sudo sed -i 's/#$nrconf{restart} = '"'"'i'"'"';/$nrconf{restart} = '"'"'a'"'"';/g' /etc/needrestart/needrestart.conf


# Avoiding unnecessary packages
# Since we are trying to make this system as minimal as possible, 
# we should make sure only the required packages are installed without 
# having to provide the --no-install-recommends option every time
echo "set default apt to --no-install-recommends"
sudo tee -a /etc/apt/apt.conf.d/99local >/dev/null <<'EOF'
APT::Install-Suggests "0";
APT::Install-Recommends "0";
Dpkg::Options {
   "--force-confdef";
   "--force-confold";
}
EOF
echo "prevent packages from installing unwanted locales"
sudo tee -a /etc/dpkg/dpkg.cfg.d/01_nolocales >/dev/null <<'EOF'
path-exclude /usr/share/locale/*
path-include /usr/share/locale/en*
EOF

sudo apt update
sudo apt dist-upgrade -y

# prevent blk_update_request: I/O error, dev fd0, sector 0 on console
# sudo rmmod floppy
# echo "blacklist floppy" | sudo tee /etc/modprobe.d/blacklist-floppy.conf
# sudo dpkg-reconfigure initramfs-tools

###########################################################
# Remove the evil that is snaps
###########################################################
sudo snap remove lxd
sudo snap remove core18
sudo snap remove snapd
sudo apt purge snapd -y

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
# setup users environment
###########################################################
# load git config with aliases and such that work for me
sudo curl -L https://raw.githubusercontent.com/traefikturkey/onvoy/master/ubuntu/notes/gitconfig -o /etc/gitconfig

mkdir $HOME/.ssh
#curl -L https://gist.githubusercontent.com/ilude/e2342829a97c3c3d3da5f9c73976c4ec/raw/authorized_keys -o $HOME/.ssh/authorized_keys
ssh-keyscan -H github.com >> $HOME/.ssh/known_hosts
ssh-keyscan -H bitbucket.org >> $HOME/.ssh/known_hosts
chmod 700 $HOME/.ssh
chmod 600 $HOME/.ssh/*

#scp $USER@rms.rammount.com:~/.ssh/id_rsa $HOME/.ssh

sudo mkdir -p /apps
sudo chown $USER:$USER /apps
    
tee -a ~/.bashrc >/dev/null <<'EOF'
alias dc='docker compose'
alias l='ls --color -lhav --group-directories-first'
alias dps='docker ps --format="table {{.Names}}\t{{.ID}}\t{{.Image}}\t{{.RunningFor}}\t{{.State}}\t{{.Status}}"'
alias dpsp='docker ps --format="table {{.Names}}\t{{.ID}}\t{{.Image}}\t{{.RunningFor}}\t{{.State}}\t{{.Status}}\t{{.Ports}}"'
EOF

sudo tee -a /etc/bash_prompt >/dev/null <<'EOF'
export PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]$(__git_ps1 "\[\033[0;33m\][\[\033[1;36m\]%s\[\033[0;33m\]]")\[\e[0m\]$ '
EOF

sudo tee -a /etc/bash_completion.d/z99_bash_prompt >/dev/null <<'EOF'
if [ -f /etc/bash_prompt ]; then
  . /etc/bash_prompt
fi
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

sudo mv /etc/cron.daily/logrotate /etc/cron.hourly/logrotate

sudo tee -a /etc/cron.weekly/docker-prune >/dev/null <<'EOF'
#!/bin/bash

/usr/bin/docker system prune -f
EOF
sudo chmod +x /etc/cron.weekly/docker-prune

sudo tee -a /etc/cron.weekly/update-system >/dev/null <<'EOF'
#!/bin/bash
/usr/bin/dpkg --configure -a
/usr/bin/apt-get update
/usr/bin/apt-get -qy dist-upgrade
/usr/bin/apt-get install -f
/usr/bin/apt-get clean
/usr/bin/apt-get -qy autoremove

if [ -f /var/run/reboot-required ]; then
sudo reboot
else
dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d' | xargs sudo apt-get -y purge
exit 0
fi
EOF
sudo chmod +x /etc/cron.weekly/update-system

# if running on a proxmox server uncomment the following
# sudo apt install qemu-guest-agent -y


###########################################################
# cleanup any mess we made
###########################################################
echo "cleaning up uneeded packages..."
sudo apt autoremove -y --purge
sudo apt autoclean -y

echo "reloading profile"
source $HOME/.profile

echo "Setup Complete!"
echo "You probably want to start a new session now!"
# force new shell so we have groups and shizzle
#exec su -l $USER
