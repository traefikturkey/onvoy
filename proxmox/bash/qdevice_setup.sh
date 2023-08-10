
# setup proxmox qdevice for quorum on seperate ubuntu machine/raspberry pi
#
# https://www.youtube.com/watch?v=jAlzBm40onc
sudo apt install corosync-qnetd -y 
sudo sed -i 's/PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config
sudo systemctl restart ssh


# on pve nodes:
apt install corosync-qdevice -y
pvecm qdevice setup $QUORUM_SERVER_IP

pvecm status
