#!/bin/bash
# copy and paste oneliner below to run
# curl -s "https://raw.githubusercontent.com/traefikturkey/onvoy/master/proxmox/bash/setup.sh?$(date +%s)" | /bin/bash -s

VERSION="$(awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release)"

# Disable Commercial Repo
sed -i "s/^deb/\#deb/" /etc/apt/sources.list.d/pve-enterprise.list

# Add PVE Community Repo
echo "deb http://download.proxmox.com/debian/pve $VERSION pve-no-subscription" > /etc/apt/sources.list.d/pve-no-enterprise.list

# add non-free-firmware repo for microcode firmware
echo "deb https://deb.debian.org/debian $VERSION main non-free-firmware" >> /etc/apt/sources.list.d/pve-no-enterprise.list

# add ceph no-subscription repo
echo "deb http://download.proxmox.com/debian/ceph-quincy $VERSION no-subscription" > /etc/apt/sources.list.d/ceph.list

# setup no nag script to run on upgrade
echo "DPkg::Post-Invoke { \"dpkg -V proxmox-widget-toolkit | grep -q '/proxmoxlib\.js$'; if [ \$? -eq 1 ]; then { echo 'Removing subscription nag from UI...'; sed -i '/data.status/{s/\!//;s/Active/NoMoreNagging/}' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js; }; fi\"; };" > /etc/apt/apt.conf.d/99-proxmox-no-nag-script

# uncomment if running a single proxmox node
# echo "Disabling high availability"
# systemctl disable -q --now pve-ha-lrm
# systemctl disable -q --now pve-ha-crm
# systemctl disable -q --now corosync
# echo "Disabled high availability"

# Proxmox now supports dark mode natively
# https://www.servethehome.com/proxmox-ve-7-4-released-with-dark-mode-support/
# the following will uninstall Weilbyte/PVEDiscordDark darkmode if it already exists
if [ -f /etc/apt/apt.conf.d/99-proxmox-dark-theme ]; then
  wget https://raw.githubusercontent.com/Weilbyte/PVEDiscordDark/master/PVEDiscordDark.sh && bash PVEDiscordDark.sh uninstall || true
  rm PVEDiscordDark.sh
  rm /etc/apt/apt.conf.d/99-proxmox-dark-theme
fi

# setup dark-theme to reinstall on upgrade
# THEME_APT_SCRIPT_FILE=/etc/apt/apt.conf.d/99-proxmox-dark-theme
# if [ ! -f "$THEME_APT_SCRIPT_FILE" ]; then
# tee -a "$THEME_APT_SCRIPT_FILE" >/dev/null <<'EOF'
# DPkg::Post-Invoke { "wget https://raw.githubusercontent.com/Weilbyte/PVEDiscordDark/master/PVEDiscordDark.sh && bash PVEDiscordDark.sh install || true"; };
# EOF
# fi

echo "Starting updates..."
apt-get update
apt-get dist-upgrade -y
echo "Updates Completed!"

# install CPU Microcode firmware
if [[ $(lscpu | grep "Vendor ID:" | grep Intel | wc -l) != 0 ]]; then
  echo "installing Intel Microcode firmware"
  apt install intel-microcode -y
fi

if [[ $(lscpu | grep "Vendor ID:" | grep AMD | wc -l) != 0 ]]; then
  echo "installing AMD Microcode firmware"
  apt install amd64-microcode -y
fi

# install ipmi/idrac tools
if [[ $(lsmod | grep ipmi | wc -l) != 0 ]]; then
    echo "Installing IPMI and configuring systemd watchdog"
    apt install openipmi ipmitool -y
    if [[ $(grep ipmi /etc/modules | wc -l) == 0 ]]; then
      echo "ipmi_watchdog" | tee /etc/modules
    fi
fi

# disable kerbose authentication for sshd, this will speed up logins
sed -i 's/GSSAPIAuthentication yes/GSSAPIAuthentication no/g' /etc/ssh/sshd_config
systemctl restart ssh

# set services to be killed after 10 seconds instead of 90 when shutdown/reboot
sed -i 's/#DefaultTimeoutStopSec=90s/DefaultTimeoutStopSec=10s/g' /etc/systemd/system.conf

# install cloud-init and guestfs tools and
# force post-invoke scripts to run
apt install -y bash-completion cloud-init dnsutils git htop iftop iotop jq libguestfs-tools make net-tools sysstat vnstat
apt autoremove -y --purge
apt autoclean -y
systemctl daemon-reload

# keep a record of when the system was setup
if ! [[ -f /etc/birth_certificate ]]; then
  echo "Creating /etc/birth_certificate"
  date > /etc/birth_certificate
fi

# check if reboot is required 
if [ -f /var/run/reboot-required ]; then
  echo "Rebooting the server now..."
  reboot
fi
