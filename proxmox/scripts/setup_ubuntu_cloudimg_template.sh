#!/bin/bash 

# curl -s "https://raw.githubusercontent.com/traefikturkey/onvoy/master/proxmox/scripts/setup_ubuntu_cloudimg_template.sh?$(date +%s)" | /bin/bash -s

CLOUDIMAGE_ENV_FILE=~/.cloudimage.env
if [[ ! -f ${CLOUDIMAGE_ENV_FILE} ]]; then
   echo 'CLOUD_INIT_USERNAME=${CLOUD_INIT_USERNAME:-anvil}' > ${CLOUDIMAGE_ENV_FILE}
   echo 'CLOUD_INIT_PASSWORD=${CLOUD_INIT_PASSWORD:-super_password}' >> ${CLOUDIMAGE_ENV_FILE}
   echo 'CLOUD_INIT_PUBLIC_KEY=$(cat ~/.ssh/id_ed25519.pub)' >> ${CLOUDIMAGE_ENV_FILE}
   echo 'VM_STORAGE=${VM_STORAGE:-local-lvm}' >> ${CLOUDIMAGE_ENV_FILE}
   echo 'VM_TIMEZONE=$(cat /etc/timezone)' >> ${CLOUDIMAGE_ENV_FILE}
   echo 'VM_SNIPPET_PATH=${VM_SNIPPET_PATH:-/var/lib/vz/snippets}' >> ${CLOUDIMAGE_ENV_FILE}
   echo 'VM_SNIPPET_LOCATION=${VM_SNIPPET_LOCATION:-local}' >> ${CLOUDIMAGE_ENV_FILE}
   echo 'GITHUB_PUBLIC_KEY_USERNAME=' >> ${CLOUDIMAGE_ENV_FILE}

   echo "please edit the ${CLOUDIMAGE_ENV_FILE} file and then rerun the same command to create the template VM"
   exit 1
fi

echo "checking for installed dependencies..."
apt-get install -y jq

eval export $(cat ${CLOUDIMAGE_ENV_FILE})

if [ -z "$CLOUD_INIT_USERNAME" ]; then
  echo "CLOUD_INIT_USERNAME is undefined, please check your ${CLOUDIMAGE_ENV_FILE} file! Exiting!"
  exit 1
fi

if [ -z "$CLOUD_INIT_PASSWORD" ]; then
  echo "CLOUD_INIT_PASSWORD is undefined, please check your ${CLOUDIMAGE_ENV_FILE} file! Exiting!"
  exit 1
fi

if [ -z "$CLOUD_INIT_PUBLIC_KEY" ]; then
  if [ ! -z "$GITHUB_PUBLIC_KEY_USERNAME" ]; then
    CLOUD_INIT_PUBLIC_KEY=$(wget -qO- https://github.com/$GITHUB_PUBLIC_KEY_USERNAME.keys | head -n1)
  else
    echo "CLOUD_INIT_PUBLIC_KEY and GITHUB_PUBLIC_KEY_USERNAME are undefined, please check your ${CLOUDIMAGE_ENV_FILE} file! Exiting!"       
    exit 1
  fi
fi

# URL of the Ubuntu cloud image directory
BASE_URL="https://cloud-images.ubuntu.com/releases/"

# Fetch the latest LTS release version
LATEST_LTS=$(curl -sL $BASE_URL | grep -P 'LTS' | grep -oP 'href="\d+\.\d+(\.\d+)?/"' | grep -oP '\d+\.\d+(\.\d+)?' | sort -Vr | head -n 1)

# Construct the URL for the latest LTS cloud image
IMAGE_URL="${BASE_URL}${LATEST_LTS}/release/"

# Fetch the actual cloud image link (e.g., .img or .qcow2)
LATEST_IMAGE=$(curl -sL $IMAGE_URL | grep -oP 'href=".*-server-cloudimg-amd64.img"' | head -n 1 | cut -d '"' -f 2)

CLOUDIMG_PATH=~/.cloudimg
TEMPLATE_PATH=$CLOUDIMG_PATH/templates/cloudinit
mkdir -p $TEMPLATE_PATH

# Output the full download link
if [[ -n "$LATEST_IMAGE" ]]; then
   REMOTE_IMAGE_URL=${IMAGE_URL}${LATEST_IMAGE}
   LOCAL_IMAGE_PATH=$CLOUDIMG_PATH/${LATEST_IMAGE}
   
   # Create VM_ID by removing periods from LATEST_LTS
   VM_ID=$(echo "$LATEST_LTS" | tr -d '.')
   VM_NAME=ubuntu-server-${LATEST_LTS}-template
else
    echo "Failed to retrieve the latest Ubuntu Server cloud image."
    exit -1
fi

echo "preparing to create $VM_NAME:$VM_ID with user $CLOUD_INIT_USERNAME stored in $VM_STORAGE"

export TEMPLATE_EXISTS=$(qm list | grep -v grep | grep -ci $VM_ID)
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

if [[ ! -f $LOCAL_IMAGE_PATH ]]; then 
   echo "downloading cloudimg file..."
   curl -sL $REMOTE_IMAGE_URL > $LOCAL_IMAGE_PATH
fi

mkdir -p $VM_SNIPPET_PATH
if [[ -f $TEMPLATE_PATH/template_cloudinit.yml ]]; then 
   echo "loading template cloudinit file..."
   envsubst < $TEMPLATE_PATH/template_cloudinit.yml > $VM_SNIPPET_PATH/template-user-data.yml
else
   echo "downloading template cloudinit file..."
   curl -s "https://raw.githubusercontent.com/traefikturkey/onvoy/master/proxmox/scripts/templates/cloudinit/template_cloudinit.yml?$(date +%s)" > $TEMPLATE_PATH/template_cloudinit.yml
   envsubst < $TEMPLATE_PATH/template_cloudinit.yml > $VM_SNIPPET_PATH/template-user-data.yml
fi

if [[ -f $TEMPLATE_PATH/clone_cloudinit.yml ]]; then 
   echo "loading clone cloudinit file..."
   envsubst < $TEMPLATE_PATH/clone_cloudinit.yml > $VM_SNIPPET_PATH/clone-user-data.yml
else
   echo "downloading clone cloudinit file..."
   curl -s "https://raw.githubusercontent.com/traefikturkey/onvoy/master/proxmox/scripts/templates/cloudinit/clone_cloudinit.yml?$(date +%s)" > $TEMPLATE_PATH/clone_cloudinit.yml
   envsubst < $TEMPLATE_PATH/clone_cloudinit.yml > $VM_SNIPPET_PATH/clone-user-data.yml
fi

echo "creating new VM..."
qm create $VM_ID --memory 2048 --cores 4 --cpu cputype=host --machine q35 --bios ovmf --net0 virtio,bridge=vmbr0 

echo "importing cloudimg $VM_STORAGE storage..."
qm importdisk $VM_ID $LOCAL_IMAGE_PATH $VM_STORAGE --format raw | grep -v 'transferred'

# finally attach the new disk to the VM as scsi drive
echo "setting vm options..."
qm set $VM_ID --name "${VM_NAME}"
qm set $VM_ID --scsihw virtio-scsi-pci 
qm set $VM_ID --scsi0 $(pvesm list $VM_STORAGE | grep "vm-$VM_ID-disk-0" | awk '{print $1}')
qm set $VM_ID --ide2 $VM_STORAGE:cloudinit
qm set $VM_ID --efidisk0 $VM_STORAGE:0,pre-enrolled-keys=0,efitype=4m,size=528K
qm set $VM_ID --boot c --bootdisk scsi0 --ostype l26
qm set $VM_ID --onboot 1
qm resize $VM_ID scsi0 +2G


qm set $VM_ID --ipconfig0 ip=dhcp
qm set $VM_ID --agent enabled=1,type=virtio,fstrim_cloned_disks=1 --localtime 1

# alternative, but the user-data.yml already has this
# qm set $VM_ID --sshkey ~/.ssh/id_ed25519.pub
qm set $VM_ID --cicustom "user=$VM_SNIPPET_LOCATION:snippets/template-user-data.yml" # qm cloudinit dump $VM_ID user

# enable the line below to generate
# log console output to $CLOUDIMG_PATH/serial.$VM_ID.log
# useful for debugging cloud-init issues
#qm terminal $VM_ID --iface serial0
#qm set $VM_ID --serial1 socket --vga serial1
qm set $VM_ID --serial0 socket #--vga serial0
qm set $VM_ID -args "-chardev file,id=char0,mux=on,path=$CLOUDIMG_PATH/serial.$VM_ID.log,signal=off -serial chardev:char0"
rm -rf $CLOUDIMG_PATH/serial.$VM_ID.log || true

echo "starting template vm..."
qm start $VM_ID

echo "waiting for QEMU guest agent to start..."
echo ""
echo "================================================================="
echo "run the following in another terminal to watch the VM's progress:"
echo "tail -f $CLOUDIMG_PATH/serial.$VM_ID.log"
echo "================================================================="
echo ""

BOOT_COMPLETE="0"
while [[ "$BOOT_COMPLETE" -ne "1" ]]; do
   sleep 5
   BOOT_COMPLETE=$(qm guest exec $VM_ID -- /bin/bash -c 'ls /var/lib/cloud/instance/boot-finished | wc -l | tr -d "\n"' | jq -r '."out-data"')
done
echo "Cloud-init of template completed!"

if [ ! -z "$GITHUB_PUBLIC_KEY_USERNAME" ]; then
  echo "importing ssh public keys from Github user $GITHUB_PUBLIC_KEY_USERNAME..."
  qm guest exec $VM_ID -- /bin/bash -c "ssh-import-id -o /home/$CLOUD_INIT_USERNAME/.ssh/authorized_keys gh:$GITHUB_PUBLIC_KEY_USERNAME "

  # GitHub API URL
  GITHUB_API_URL="https://api.github.com/users/$GITHUB_PUBLIC_KEY_USERNAME/repos"

  # Fetch the list of repositories and check for 'dotfiles'
  if curl -s "$GITHUB_API_URL" | grep -q '"name": "dotfiles"'; then
    echo "Dotfiles repository found for user: $GITHUB_PUBLIC_KEY_USERNAME"
    qm guest exec $VM_ID -- /bin/bash -c "git clone https://github.com/ilude/dotfiles.git /home/$CLOUD_INIT_USERNAME/.dotfiles"
  fi

  qm guest exec $VM_ID -- /bin/bash -c "chown -R $CLOUD_INIT_USERNAME:$CLOUD_INIT_USERNAME /home/$CLOUD_INIT_USERNAME"
fi

echo "setting user $CLOUD_INIT_USERNAME password..."
qm guest exec $VM_ID -- /bin/bash -c "echo \"$CLOUD_INIT_USERNAME:$CLOUD_INIT_PASSWORD\" | chpasswd"

echo "saving log files and cleaning up..."
qm guest exec $VM_ID -- /bin/bash -c 'cloud-init collect-logs'
qm guest exec $VM_ID -- /bin/bash -c 'cloud-init clean'

echo "setting cloud-init to use user=$VM_SNIPPET_LOCATION:snippets/clone-user-data.yml..." 
qm set $VM_ID --cicustom "user=$VM_SNIPPET_LOCATION:snippets/clone-user-data.yml" 
# qm cloudinit dump $VM_ID user

echo "shutting down and converting to template VM..."
qm shutdown $VM_ID
qm stop $VM_ID

qm set $VM_ID --delete args
qm template $VM_ID
echo "Operations Completed!"
