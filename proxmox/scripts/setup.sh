#!/bin/bash
# Proxmox VE setup script for community/no-subscription installations
# Usage: Run the following one-liner in your terminal to execute this script directly:
# curl -s "https://raw.githubusercontent.com/traefikturkey/onvoy/master/proxmox/scripts/setup.sh?$(date +%s)" | /bin/bash -s

# Detect the Debian/Proxmox version codename (e.g., bullseye, bookworm)
VERSION="$(awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release)"

# Disable the commercial (enterprise) Proxmox repository to avoid subscription prompts
sed -i "s/^deb/\#deb/" /etc/apt/sources.list.d/pve-enterprise.list

# Add the Proxmox community (no-subscription) repository for updates
echo "deb http://download.proxmox.com/debian/pve $VERSION pve-no-subscription" > /etc/apt/sources.list.d/pve-no-enterprise.list

# Add Debian non-free-firmware repo to enable installation of CPU microcode and other firmware
echo "deb https://deb.debian.org/debian $VERSION main non-free-firmware" >> /etc/apt/sources.list.d/pve-no-enterprise.list

# Add Ceph no-subscription repository for distributed storage features
echo "deb http://download.proxmox.com/debian/ceph-quincy $VERSION no-subscription" > /etc/apt/sources.list.d/ceph.list

# Create a script to automatically remove the Proxmox subscription nag from the web UI after upgrades
echo "DPkg::Post-Invoke { \"dpkg -V proxmox-widget-toolkit | grep -q '/proxmoxlib\.js$'; if [ \$? -eq 1 ]; then { echo 'Removing subscription nag from UI...'; sed -i '/data.status/{s/\!//;s/Active/NoMoreNagging/}' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js; }; fi\"; };" > /etc/apt/apt.conf.d/99-proxmox-no-nag-script

# Optional: Disable high availability services if running a single Proxmox node (uncomment to use)
# echo "Disabling high availability"
# systemctl disable -q --now pve-ha-lrm
# systemctl disable -q --now pve-ha-crm
# systemctl disable -q --now corosync
# echo "Disabled high availability"

# If a third-party dark mode theme (Weilbyte/PVEDiscordDark) was previously installed, uninstall it
# Proxmox now supports dark mode natively as of version 7.4
if [ -f /etc/apt/apt.conf.d/99-proxmox-dark-theme ]; then
  wget https://raw.githubusercontent.com/Weilbyte/PVEDiscordDark/master/PVEDiscordDark.sh && bash PVEDiscordDark.sh uninstall || true
  rm PVEDiscordDark.sh
  rm /etc/apt/apt.conf.d/99-proxmox-dark-theme
fi

# Optional: Set up dark mode theme to reinstall after upgrades (commented out by default)
# THEME_APT_SCRIPT_FILE=/etc/apt/apt.conf.d/99-proxmox-dark-theme
# if [ ! -f "$THEME_APT_SCRIPT_FILE" ]; then
# tee -a "$THEME_APT_SCRIPT_FILE" >/dev/null <<'EOF'
# DPkg::Post-Invoke { "wget https://raw.githubusercontent.com/Weilbyte/PVEDiscordDark/master/PVEDiscordDark.sh && bash PVEDiscordDark.sh install || true"; };
# EOF
# fi

# Update package lists and upgrade installed packages
echo "Starting updates..."
apt-get update
apt-get dist-upgrade -y
echo "Updates Completed!"

# Detect CPU vendor and install appropriate microcode firmware for security and stability
if [[ $(lscpu | grep "Vendor ID:" | grep Intel | wc -l) != 0 ]]; then
  echo "installing Intel Microcode firmware"
  apt install intel-microcode -y
fi

if [[ $(lscpu | grep "Vendor ID:" | grep AMD | wc -l) != 0 ]]; then
  echo "installing AMD Microcode firmware"
  apt install amd64-microcode -y
fi

# If IPMI modules are loaded, install IPMI tools and configure systemd watchdog for hardware monitoring
if [[ $(lsmod | grep ipmi | wc -l) != 0 ]]; then
    echo "Installing IPMI and configuring systemd watchdog"
    apt install openipmi ipmitool -y
    # Ensure ipmi_watchdog is loaded at boot
    if [[ $(grep ipmi /etc/modules | wc -l) == 0 ]]; then
      echo "ipmi_watchdog" | tee /etc/modules
    fi
fi

# Disable Kerberos (GSSAPI) authentication in SSH to speed up login times
sed -i 's/GSSAPIAuthentication yes/GSSAPIAuthentication no/g' /etc/ssh/sshd_config
systemctl restart ssh

# Reduce systemd service stop timeout from 90s to 10s for faster shutdowns/reboots
sed -i 's/#DefaultTimeoutStopSec=90s/DefaultTimeoutStopSec=10s/g' /etc/systemd/system.conf

# Install common utilities and tools for system management and VM/CT provisioning
apt install -y bash-completion dnsutils git htop iftop iotop jq libguestfs-tools make net-tools sysstat vnstat zsh
apt autoremove -y --purge    # Remove unnecessary packages
apt autoclean -y             # Clean up package cache
systemctl daemon-reload      # Reload systemd configuration

# Create a file to record the setup date if it doesn't already exist
if ! [[ -f /etc/birth_certificate ]]; then
  echo "Creating /etc/birth_certificate"
  date > /etc/birth_certificate
fi

# If a reboot is required after updates, reboot automatically
if [ -f /var/run/reboot-required ]; then
  echo "Rebooting the server now..."
  reboot
fi
