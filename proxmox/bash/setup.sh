# copy and paste oneliner below to run
# curl -s https://raw.githubusercontent.com/traefikturkey/onvoy/master/proxmox/bash/setup.sh?$(date +%s) | /bin/bash -s

# Disable Commercial Repo
sed -i "s/^deb/\#deb/" /etc/apt/sources.list.d/pve-enterprise.list

# Add PVE Community Repo
echo "deb http://download.proxmox.com/debian/pve $(grep "VERSION=" /etc/os-release | sed -n 's/.*(\(.*\)).*/\1/p') pve-no-subscription" > /etc/apt/sources.list.d/pve-no-enterprise.list

# setup no nag script to run on upgrade
echo "DPkg::Post-Invoke { \"dpkg -V proxmox-widget-toolkit | grep -q '/proxmoxlib\.js$'; if [ \$? -eq 1 ]; then { echo 'Removing subscription nag from UI...'; sed -i '/data.status/{s/\!//;s/Active/NoMoreNagging/}' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js; }; fi\"; };" > /etc/apt/apt.conf.d/99-proxmox-no-nag-script

# setup dark-theme to reinstall on upgrade
THEME_APT_SCRIPT_FILE=/etc/apt/apt.conf.d/99-proxmox-dark-theme
if [ ! -f "$THEME_APT_SCRIPT_FILE" ]; then
tee -a "$THEME_APT_SCRIPT_FILE" >/dev/null <<'EOF'
DPkg::Post-Invoke { "wget https://raw.githubusercontent.com/Weilbyte/PVEDiscordDark/master/PVEDiscordDark.sh && bash PVEDiscordDark.sh install || true"; };
EOF
fi

apt-get update
apt-get dist-upgrade -y

# disable kerbose authentication for sshd, this will speed up logins
sed -i 's/GSSAPIAuthentication yes/GSSAPIAuthentication no/g' /etc/ssh/sshd_config
systemctl restart ssh

# force post-invoke scripts to run
apt --reinstall install proxmox-widget-toolkit

# keep a record of when the system was setup
if ! [[ -f /etc/birth_certificate ]]; then
  echo "Creating /etc/birth_certificate"
  date > /etc/birth_certificate
fi



# check if reboot is required 
if [ -f /var/run/reboot-required ]; then
  sudo reboot
fi
