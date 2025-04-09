#!/bin/bash

# Check root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run as root"
  exit 1
fi

echo 'GRUB_CMDLINE_LINUX_DEFAULT="${GRUB_CMDLINE_LINUX_DEFAULT} ipv6.disable=1"' >> /etc/default/grub.d/ipv6-disable.cfg
update-grub
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
sysctl -w net.ipv6.conf.lo.disable_ipv6=1
sysctl -w "kernel.printk = 3 4 1 3"
sysctl -w vm.overcommit_memory=1
sysctl -w net.core.somaxconn=1024
sysctl -w vm.max_map_count=262144
sysctl -w vm.swappiness=1
