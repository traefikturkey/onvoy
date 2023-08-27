#!/bin/bash 

# curl -s https://raw.githubusercontent.com/traefikturkey/onvoy/master/proxmox/bash/setup_ubuntu_cloudimg_template.sh > setup_ubuntu_cloudimg_template.sh

# qm stop 9000 --skiplock && qm destroy 9000 --destroy-unreferenced-disks --purge

if [[ ! -f .env ]]; then
   echo "CLOUD_INIT_USERNAME=<your_username_here>" > .env
   echo "CLOUD_INIT_PASSWORD=<your_password_here>" >> .env
   echo "CLOUD_INIT_PUBLIC_KEY=$(cat ~/.ssh/id_ed25519.pub)" >> .env
   echo "VM_ID=${VM_ID:-9000}" >> .env
   echo "VM_STORAGE=${VM_STORAGE:-local-lvm}" >> .env
   echo "VM_NAME=${VM_NAME:-ubuntu-server-22.04-template}" >> .env

   echo "please edit the .env file and then rerun the same command to create the template VM"
   exit 1
else
   eval export $(cat .env)
fi

if [[ ! -f jammy-server-cloudimg-amd64.img ]]; then 
   echo "downloading cloudimg file..."
   wget -nc https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
fi

if [[ ! -f basic_cloudinit.yml ]]; then 
   echo "downloading cloudinit file..."
   curl -s "https://raw.githubusercontent.com/traefikturkey/onvoy/master/proxmox/bash/templates/cloudinit/basic_cloudinit.yml?$(date +%s)" -o basic_cloudinit.yml
fi

echo "setup cloudinit file..."
mkdir -p /var/lib/vz/snippets/
envsubst < basic_cloudinit.yml > /var/lib/vz/snippets/user-data.yml

echo "creating new VM..."
qm create $VM_ID --memory 2048 --cores 4 --machine q35 --bios ovmf --net0 virtio,bridge=vmbr0 

echo "importing cloudimg $VM_STORAGE storage..."
qm importdisk $VM_ID jammy-server-cloudimg-amd64.img $VM_STORAGE > /dev/null

# finally attach the new disk to the VM as scsi drive
qm set $VM_ID --name "${VM_NAME}"
qm set $VM_ID --scsihw virtio-scsi-pci --scsi0 $VM_STORAGE:vm-9000-disk-0,cache=writethrough,discard=on,ssd=1
qm set $VM_ID --scsi1 $VM_STORAGE:cloudinit
qm set $VM_ID --efidisk0 $VM_STORAGE:0,pre-enrolled-keys=1,efitype=4m,size=528K
qm set $VM_ID --boot c --bootdisk scsi0 --ostype l26
qm set $VM_ID --serial0 socket --vga serial0
qm set $VM_ID --ipconfig0 ip=dhcp
qm set $VM_ID --agent enabled=1,type=virtio,fstrim_cloned_disks=1 --localtime 1
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

echo "shutting down and converting to template VM..."
qm shutdown $VM_ID
qm stop $VM_ID
qm template $VM_ID
echo "Operations Completed!"
