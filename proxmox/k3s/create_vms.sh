#!/bin/bash

# curl -s "https://raw.githubusercontent.com/traefikturkey/onvoy/master/proxmox/bash/k3s/create_vms.sh?$(date +%s)" | /bin/bash -s

create_vm () {
  local VM_ID=$1
  local VM_NAME=$2
  local VM_MEM=$3
  local VM_SIZE=$4
  qm clone 9000 $VM_ID --name $VM_NAME --full false
  qm set $VM_ID --memory $VM_MEM
  qm resize $VM_ID scsi0 +$VM_SIZE

  # hack to set the hostname of the vm
  UUID=$(qm config $VM_ID | grep smbios1: | awk -F'=' '{ print $2 }')
  qm set $VM_ID --smbios1 uuid=$UUID,serial=$(echo -n "ds=nocloud;hostname=$VM_NAME" | base64),base64=1
  
  qm start $VM_ID
}

create_vm 201 k3s-manager-1 8192 12G
create_vm 202 k3s-manager-2 8192 12G
create_vm 203 k3s-manager-3 8192 12G
create_vm 211 k3s-worker-1 16384 60G
create_vm 212 k3s-worker-2 16384 60G
