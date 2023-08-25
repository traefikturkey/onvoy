#!/bin/bash 

# curl -s https://raw.githubusercontent.com/traefikturkey/onvoy/master/proxmox/bash/setup_ubuntu_cloudimg_template.sh > setup_ubuntu_cloudimg_template.sh

export CLOUD_INIT_USERNAME=<your_username_here>
export CLOUD_INIT_PASSWORD=<your_password_here>
export CLOUD_INIT_PUBLIC_KEY=$(cat ~/.ssh/id_ed25519.pub)
export VM_ID=${VM_ID:-9000}
export VM_STORAGE=${VM_STORAGE:-local-lvm}

echo "downloading cloudimg file..."
wget -nc https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

echo "downloading cloudinit file..."
wget -nc https://github.com/traefikturkey/onvoy/raw/master/proxmox/bash/templates/cloudinit/basic_cloudinit.yml

echo "installing cloudinit and guest-agent dependencies..."
apt update
apt install -y cloud-init libguestfs-tools

echo "adding guest-agent to cloudimg..."
virt-customize --install qemu-guest-agent -a jammy-server-cloudimg-amd64.img

mkdir -p /var/lib/vz/snippets/
envsubst < basic_cloudinit.yml > /var/lib/vz/snippets/user-data.yml

echo "creating new VM..."
qm create $VM_ID --memory 2048 --cores 4 --machine q35 --bios ovmf --net0 virtio,bridge=vmbr0 

echo "importing cloudimg $VM_STORAGE storage..."
qm importdisk $VM_ID jammy-server-cloudimg-amd64.img $VM_STORAGE > /dev/null

# finally attach the new disk to the VM as scsi drive
qm set $VM_ID --name "ubuntu-22.04-server"
qm set $VM_ID --scsihw virtio-scsi-pci --scsi0 $VM_STORAGE:vm-9000-disk-0
qm set $VM_ID --ide2 $VM_STORAGE:cloudinit
qm set $VM_ID --efidisk0 $VM_STORAGE:0,pre-enrolled-keys=1,efitype=4m
qm set $VM_ID --boot c --bootdisk scsi0 --ostype l26
qm set $VM_ID --serial0 socket --vga serial0
qm set $VM_ID --ipconfig0 ip=dhcp
qm set $VM_ID --agent enabled=1,type=virtio --localtime 1
# alternative, but the user-data.yml already has this
#qm set $VM_ID --sshkey ~/.ssh/id_ed25519.pub

# qm cloudinit dump 9000 user > /var/lib/vz/snippets/user-data.yml; nano /var/lib/vz/snippets/user-data.yml
qm set $VM_ID --cicustom "user=local:snippets/user-data.yml"

echo "starting template vm..."
qm start $VM_ID

echo "waiting for template vm to complete initial setup..."
secs=110
while [ $secs -gt 0 ]; do
   echo -ne "\t$secs seconds remaining\033[0K\r"
   sleep 1
   : $((secs--))
done

echo "initial setup complete..."
qm shutdown $VM_ID
qm stop $VM_ID
qm template $VM_ID


