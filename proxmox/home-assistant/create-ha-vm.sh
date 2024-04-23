#!/bin/bash 

# https://www.home-assistant.io/installation/linux

# https://github.com/home-assistant/operating-system/releases/
VERSION=11.0.rc1
IMAGE_FILE=haos_generic-aarch64-${VERSION}.qcow2

VM_ID=${VM_ID:-127001}
VM_STORAGE=${VM_STORAGE:-local-lvm}
VM_NAME=${VM_NAME:-home-assistant}
VM_TIMEZONE=${TZ:-$(cat /etc/timezone)}

apt install xz-utils -y

TEMPLATE_EXISTS=$(qm list | grep -v grep | grep -ci $VM_ID)
if [[ $TEMPLATE_EXISTS > 0 ]]; then
   echo "VM $VM_ID already exists, will delete in 5 seconds... CTRL-C to stop now!"
   secs=6
   while [ $secs -gt 0 ]; do
      echo -ne "\t$secs seconds remaining\033[0K\r"
      sleep 1
      : $((secs--))
   done
   echo ""
   qm stop $VM_ID --skiplock && qm destroy $VM_ID --destroy-unreferenced-disks --purge
fi

if [[ ! -f /tmp/haos_generic-aarch64-${VERSION}.qcow2 ]]; then 
   echo "downloading home-assistant image"
   wget -q --show-progress https://github.com/home-assistant/operating-system/releases/download/${VERSION}/${IMAGE_FILE}.xz -O /tmp/${IMAGE_FILE}.xz

   echo "decompressing /tmp/${IMAGE_FILE}.xz"
   xz --decompress /tmp/${IMAGE_FILE}.xz
   echo "decompress completed"
fi

echo "creating new VM..."
qm create $VM_ID --memory 4096 --cores 4 --machine q35 --bios ovmf --net0 virtio,bridge=vmbr0 

echo "importing cloudimg $VM_STORAGE storage..."
qm importdisk $VM_ID /tmp/${IMAGE_FILE} $VM_STORAGE --format qcow2 | grep -v 'transferred'

echo "setting vm options..."
qm set $VM_ID --name "${VM_NAME}"
qm set $VM_ID --scsihw virtio-scsi-pci 
qm set $VM_ID --scsi0 $(pvesm list $VM_STORAGE | grep "vm-$VM_ID-disk-0" | awk '{print $1}')
qm set $VM_ID --efidisk0 $VM_STORAGE:0,pre-enrolled-keys=1,efitype=4m,size=528K
qm set $VM_ID --boot order=scsi0 --ostype l26
qm set $VM_ID --onboot 1
qm set $VM_ID --serial0 socket #--vga serial0
qm set $VM_ID --ipconfig0 ip=dhcp
qm set $VM_ID --agent enabled=1,type=virtio,fstrim_cloned_disks=1 --localtime 1

echo "starting template vm..."
qm start $VM_ID

