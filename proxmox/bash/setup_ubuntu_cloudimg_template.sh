#!/bin/bash 

export CLOUND_INIT_USERNAME=<your_username_here>
export CLOUND_INIT_PASSWORD=<your_password_here>
export CLOUND_INIT_PUBLIC_KEY=$(cat ~/.ssh/authorized_keys | grep <your_email_here> )
export VM_STORAGE=${VM_STORAGE:-local-lvm}

wget -nc https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
wget -nc https://github.com/traefikturkey/onvoy/raw/master/proxmox/bash/templates/cloudinit/basic_cloudinit.yml

mkdir -p /var/lib/vz/snippets/
envsubst < basic_cloudinit.yml > /var/lib/vz/snippets/user-data.yml

# create a new VM
qm create 9000 --memory 2048 --cores 4 --machine q35 --bios ovmf --net0 virtio,bridge=vmbr0 

# import the downloaded disk to local-lvm storage
qm importdisk 9000 jammy-server-cloudimg-amd64.img $VM_STORAGE > /dev/null

# finally attach the new disk to the VM as scsi drive
qm set 9000 --scsihw virtio-scsi-pci --scsi0 $VM_STORAGE:vm-9000-disk-0
qm set 9000 --ide2 $VM_STORAGE:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --ipconfig0 ip=dhcp

# qm cloudinit dump 9000 user > /var/lib/vz/snippets/user-data.yml; nano /var/lib/vz/snippets/user-data.yml
qm set 9000 --cicustom "user=local:snippets/user-data.yml"

echo "starting template vm..."
qm start 9000

