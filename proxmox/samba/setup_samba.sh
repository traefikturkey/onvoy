#!/bin/bash
# On the proxmox server:

apt-get update
apt-get install samba

# add root as a samba user and create a password
smbpasswd

# It would also be nice to not have to connect as root to the server every time.
# Lets create a new user and give them samba permissions.

# To create a new Unix user:
useradd -m $USERNAME
passwd $USERNAME

# This adds the new user to Samba.
smbpasswd -a $USERNAME

cp /etc/samba/smb.conf /etc/samba/smb.conf.bak
curl -s "https://raw.githubusercontent.com/traefikturkey/onvoy/master/proxmox/samba/smb.conf" > /etc/samba/smb.conf

nano /etc/samba/smb.conf

service smbd stop
service smbd start

# Test for errors.
testparm
