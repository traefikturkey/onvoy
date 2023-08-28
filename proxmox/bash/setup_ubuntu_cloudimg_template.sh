#!/bin/bash 

# curl -s "https://raw.githubusercontent.com/traefikturkey/onvoy/master/proxmox/bash/setup_ubuntu_cloudimg_template.sh?$(date +%s)" | /bin/bash -s

# qm stop 9000 --skiplock && qm destroy 9000 --destroy-unreferenced-disks --purge

if [[ ! -f .env ]]; then
   echo 'CLOUD_INIT_USERNAME=<your_username_here>' > .env
   echo 'CLOUD_INIT_PASSWORD=<your_password_here>' >> .env
   echo 'CLOUD_INIT_PUBLIC_KEY=$(cat ~/.ssh/id_ed25519.pub)' >> .env
   echo 'VM_ID=${VM_ID:-9000}' >> .env
   echo 'VM_STORAGE=${VM_STORAGE:-local-lvm}' >> .env
   echo 'VM_NAME=${VM_NAME:-ubuntu-server-22.04-template}' >> .env

   echo "please edit the .env file and then rerun the same command to create the template VM"
   exit 1
else
   eval export $(cat .env)
fi

if [[ ! -f /tmp/jammy-server-cloudimg-amd64.img ]]; then 
   echo "downloading cloudimg file..."
   curl -s https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img >/tmp/jammy-server-cloudimg-amd64.img
fi

echo "downloading template cloudinit file..."
curl -s "https://github.com/traefikturkey/onvoy/edit/master/proxmox/bash/templates/cloudinit/template_cloudinit.yml?$(date +%s)" -o /tmp/template_cloudinit.yml
mkdir -p /var/lib/vz/snippets/
envsubst < /tmp/template_cloudinit.yml > /var/lib/vz/snippets/template-user-data.yml
#rm -f /tmp/template_cloudinit.yml

echo "downloading clone cloudinit file..."
curl -s "https://github.com/traefikturkey/onvoy/edit/master/proxmox/bash/templates/cloudinit/clone_cloudinit.yml?$(date +%s)" -o /tmp/clone_cloudinit.yml
envsubst < /tmp/clone_cloudinit.yml > /var/lib/vz/snippets/clone-user-data.yml
#rm -f /tmp/clone_cloudinit.yml

echo "creating new VM..."
qm create $VM_ID --memory 2048 --cores 4 --machine q35 --bios ovmf --net0 virtio,bridge=vmbr0 

echo "importing cloudimg $VM_STORAGE storage..."
qm importdisk $VM_ID /tmp/jammy-server-cloudimg-amd64.img $VM_STORAGE > /dev/null

# finally attach the new disk to the VM as scsi drive
qm set $VM_ID --name "${VM_NAME}"
qm set $VM_ID --scsihw virtio-scsi-pci --scsi0 $VM_STORAGE:vm-$VM_ID-disk-0,cache=writethrough,discard=on,ssd=1
qm set $VM_ID --scsi1 $VM_STORAGE:cloudinit
qm set $VM_ID --cicustom "user=local:snippets/template-user-data.yml" # qm cloudinit dump 9000 user
qm set $VM_ID --efidisk0 $VM_STORAGE:0,pre-enrolled-keys=1,efitype=4m,size=528K
qm set $VM_ID --boot c --bootdisk scsi0 --ostype l26
qm set $VM_ID --serial0 socket --vga serial0
qm set $VM_ID --ipconfig0 ip=dhcp
qm set $VM_ID --agent enabled=1,type=virtio,fstrim_cloned_disks=1 --localtime 1
# alternative, but the user-data.yml already has this
# qm set $VM_ID --sshkey ~/.ssh/id_ed25519.pub

echo "starting template vm..."
qm start $VM_ID

echo "waiting for template vm boot..."
secs=75
while [ $secs -gt 0 ]; do
   echo -ne "\t$secs seconds remaining\033[0K\r"
   sleep 1
   : $((secs--))
done
echo ""
echo "booting complete, waiting for QEMU guest agent to start..."

BOOT_COMPLETE="0"
while [[ "$BOOT_COMPLETE" -ne "1" ]]; do
   BOOT_COMPLETE=$(qm guest exec $VM_ID -- /bin/bash -c 'ls /var/lib/cloud/instance/boot-finished | wc -l | tr -d "\n"' | jq -r '."out-data"')
   sleep 5
done

qm guest exec $VM_ID -- /bin/bash -c 'truncate -s 0 /etc/machine-id && chmod 600 /etc/machine-id && rm /var/lib/dbus/machine-id && ln -s /etc/machine-id  /var/lib/dbus/machine-id'

echo "shutting down and converting to template VM..."
qm shutdown $VM_ID
qm stop $VM_ID

qm resize $VM_ID scsi0 +8G

qm template $VM_ID
echo "Operations Completed!"
