#!/bin/sh

# curl -s "https://raw.githubusercontent.com/traefikturkey/onvoy/refs/heads/main/ubuntu/bash/base_server_setup.sh?$(date +%s)" | /bin/bash -s

# Fire and forget
export DEBIAN_FRONTEND=noninteractive

# https://askubuntu.com/a/1424249
echo "disable pending kernel upgrade message"
sudo sed -i "s/#\$nrconf{kernelhints} = -1;/\$nrconf{kernelhints} = -1;/g" /etc/needrestart/needrestart.conf

# https://askubuntu.com/a/1421221
echo "disable autorestart message"
sudo sed -i 's/#$nrconf{restart} = '"'"'i'"'"';/$nrconf{restart} = '"'"'a'"'"';/g' /etc/needrestart/needrestart.conf

# Avoiding unnecessary packages
# Since we are trying to make this system as minimal as possible, 
# we should make sure only the required packages are installed without 
# having to provide the --no-install-suggests option every time
echo "set default apt to --no-install-suggests"
sudo tee -a /etc/apt/apt.conf.d/99local >/dev/null <<'EOF'
APT::Install-Suggests "0";
APT::Install-Recommends "1";
Apt::Cmd::Disable-Script-Warning "true";
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

sudo apt-get update
sudo apt-get full-upgrade -y

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
#sudo timedatectl set-timezone America/Los_Angeles
sudo timedatectl set-timezone America/New_York
sudo timedatectl set-local-rtc 1 # 1=local 0=UTC
sudo timedatectl set-ntp true

# disable ip6
sudo sysctl net.ipv6.conf.all.disable_ipv6=1
sudo sysctl net.ipv6.conf.default.disable_ipv6=1
echo "net.ipv6.conf.all.disable_ipv6=1" | sudo tee --append /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6=1" | sudo tee --append /etc/sysctl.conf

# basic system administration packages
sudo apt-get update
sudo apt-get install -y \
    anacron \
    apt-transport-https \
    btop \
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
    
sudo apt-get purge -y landscape-common

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
sudo apt-get purge snapd -y

###########################################################
# setup users environment
###########################################################
# load git config with aliases and such that work for me
sudo curl -L https://raw.githubusercontent.com/traefikturkey/onvoy/main/shell/git/gitconfig -o /etc/gitconfig

mkdir $HOME/.ssh
#curl -L https://gist.githubusercontent.com/ilude/e2342829a97c3c3d3da5f9c73976c4ec/raw/authorized_keys -o $HOME/.ssh/authorized_keys
ssh-keyscan -H github.com >> $HOME/.ssh/known_hosts
ssh-keyscan -H bitbucket.org >> $HOME/.ssh/known_hosts
chmod 700 $HOME/.ssh
chmod 600 $HOME/.ssh/*

sudo mkdir -p /apps
sudo chown $USER:$USER /apps

sudo tee -a /etc/bash_prompt >/dev/null <<'EOF'
export PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]$(__git_ps1 "\[\033[0;33m\][\[\033[1;36m\]%s\[\033[0;33m\]]")\[\e[0m\]$ '
EOF

sudo tee -a /etc/bash_completion.d/z99_bash_prompt >/dev/null <<'EOF'
if [ -f /etc/bash_prompt ]; then
  . /etc/bash_prompt
fi
EOF

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

###########################################################
# cleanup any mess we made
###########################################################
echo "cleaning up uneeded packages..."
sudo apt-get autoremove -y --purge
sudo apt-get autoclean -y

echo "Setup Complete!"
echo "You probably want to start a new session now!"
