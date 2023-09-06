##############################################################
# zfs samba file sharing
# https://forum.level1techs.com/t/how-to-create-a-nas-using-zfs-and-proxmox-with-pictures/117375

# On the root proxmox server:

apt-get update
apt-get install samba

# add root as a samba user and create a password
smbpasswd

# It would also be nice to not have to connect as root to the server every time.
# Lets create a new user and give them samba permissions.

# To create a new Unix user:
useradd -m mike
passwd mike

# This adds the new user to Samba.
smbpasswd -a mike

nano /etc/samba/smb.conf

service smbd stop
service smbd start

# Test for errors.
testparm
