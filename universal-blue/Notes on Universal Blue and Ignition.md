# Fedora Univeral Blue Images

Copied directly from my notes so it probably has some non-working links.

### Installing Universal Blue images

Universal Blue is based on CoreOS and don't have their own installer.
Instead they provide a specific \[\[CoreOS Ignition File\|ignition\]\]
file that allows you to rebase an existing CoreOS image to Universal
Blue.

They have various image tags based on what you want in your image, for
example:

- stable
- stable-zfs
- stable-nvidia-zfs

Modify your Butane config accordingly to which one you want.

#### Basic Universal Blue ignition file

Looking at the [Ignition config spec](https://coreos.github.io/butane/specs/) is very helpful when creating your own config.

```yaml
variant: fcos
version: 1.6.0
passwd:
  users:
    - name: sysadmin
      ssh_authorized_keys:
        - ssh-ed25519 dadfdagadfaf
      password_hash: YOUR_VALID_PASSWORD_HASH_HERE
      groups:
        - sudo
storage:
  directories:
    - path: /etc/ucore-autorebase
      mode: 0754
systemd:
  units:
    - name: ucore-unsigned-autorebase.service
      enabled: true
      contents: |
        [Unit]
        Description=uCore autorebase to unsigned OCI and reboot
        ConditionPathExists=!/etc/ucore-autorebase/unverified
        ConditionPathExists=!/etc/ucore-autorebase/signed
        After=network-online.target
        Wants=network-online.target
        [Service]
        Type=oneshot
        StandardOutput=journal+console
        ExecStart=/usr/bin/rpm-ostree rebase --bypass-driver ostree-unverified-registry:ghcr.io/ublue-os/ucore:stable
        ExecStart=/usr/bin/touch /etc/ucore-autorebase/unverified
        ExecStart=/usr/bin/systemctl disable ucore-unsigned-autorebase.service
        ExecStart=/usr/bin/systemctl reboot
        [Install]
        WantedBy=multi-user.target
    - name: ucore-signed-autorebase.service
      enabled: true
      contents: |
        [Unit]
        Description=uCore autorebase to signed OCI and reboot
        ConditionPathExists=/etc/ucore-autorebase/unverified
        ConditionPathExists=!/etc/ucore-autorebase/signed
        After=network-online.target
        Wants=network-online.target
        [Service]
        Type=oneshot
        StandardOutput=journal+console
        ExecStart=/usr/bin/rpm-ostree rebase --bypass-driver ostree-image-signed:docker://ghcr.io/ublue-os/ucore:stable
        ExecStart=/usr/bin/touch /etc/ucore-autorebase/signed
        ExecStart=/usr/bin/systemctl disable ucore-signed-autorebase.service
        ExecStart=/usr/bin/systemctl reboot
        [Install]
        WantedBy=multi-user.target
```

#### Generating a password hash for your ignition file.

It's safer to use their docker / podman image to make sure that you get
the right version of mkpasswd.

```bash
docker run -ti --rm quay.io/coreos/mkpasswd --method=yescrypt
```

#### Providing the OS with the ignition file.

For now I'll just host it on an HTTP server running internally.

Add this to the kernel boot parameters.

```#
ignition.config.url=http://<your_http_server_ip>:<port>/your.ign
```

#### Merging Ignition config files

Butane supports merging existing Ignition config files into your Butane
syntax like this:

    ignition:
      config:
        merge:
        - inline: '{"ignition": {"version": "3.5.0"}}'

Instead of `inline` you can also use local files `local` or a file on an
HTTP server `source`.

# CoreOS Ignition File

### What is an Ignition file

An Ignition file is a starter config. This is something that only runs
_once_, at first boot.

You shouldn't get too deep on configuring things in this file, stick to
the basics, things that the host needs. Users, etc.

Workloads on CoreOS images are designed to run in container engines like
Docker or Podman.

### Create an ignition file

This file contains the minimal information to get your system up and
running (username, ssh key, etc)

[Source](https://docs.fedoraproject.org/en-US/fedora-coreos/producing-ign/)

Butane is the tool used to generate ignition files.

1.  Pull the latest image

    `sudo docker pull quay.io/coreos/butane:release`

2.  Create a yaml file containing the Butane config (example below)

    ```yaml
    variant: fcos
    version: 1.6.0
    passwd:
    users:
      - name: sysadmin
        ssh_authorized_keys:
          - ssh-ed25519 adfadfamfdfad
    ```

    Save the file as `filename.bu`

3.  Generate your .ign file from the yaml source. You can install this
    tool natively, but why when Docker exists.

    ```bash
    docker run --interactive --rm quay.io/coreos/butane:release \
       --pretty --strict < ./filename.bu > transpiled_config.ign
    ```

4.  Your .ign file needs to be hosted on an HTTP server somewhere that
    the Core OS installer can find. There are other options that I have
    not yet explored such as hook scripts. As of right now I just have
    an nginx webserver serving these files on my local network where
    these machines can find them.

### Using the Ignition file

See \[\[Fedora Univeral Blue Images.md#Providing the OS with the
ignition file.\]\]

# Setting up Fedora CoreOS or Universal Blue on Proxmox

## Creating the custom template in Proxmox

```bash
#!/bin/bash

# Get your download link for CoreOS here: https://fedoraproject.org/coreos/download?stream=stable.
# You want the qcow2 image for Proxmox.

if [ "$EUID" -ne 0 ]
  then echo "Please run as root."
  exit
fi

apt-get install xz-utils -y

wget https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/42.20250427.3.0/x86_64/fedora-coreos-42.20250427.3.0-qemu.x86_64.qcow2.xz

xz -dv fedora-coreos-42.20250427.3.0-qemu.x86_64.qcow2.xz

rm fedora-coreos-42.20250427.3.0-qemu.x86_64.qcow2.xz

VM_ID=7000
VM_STORAGE=fast

# Create the VM
qm create ${VM_ID} --name fedora-ublue

# Set options
qm set ${VM_ID} --memory 2048 \
      --cpu x86-64-v2-AES
      --cores 2 \
      --agent enabled=1 \
      --autostart \
      --onboot 1 \
      --scsihw virtio-scsi-pci \
      --ostype l26 \
      --tablet 0 \
      --boot c --bootdisk scsi0
      --net0 virtio,bridge=vmbr0
      --ide2 ${VM_STORAGE}:cloudinit

# Import the Fedora CoreOS image
qm importdisk ${VM_ID} fedora-coreos-42.20250427.3.0-qemu.x86_64.qcow2 fast

qm set ${VM_ID} --scsihw virtio-scsi-pci --scsi0 ${VM_STORAGE}:vm-${VM_ID}-disk-0,discard=on

qm template ${VM_ID}
```

I got a lot of help from this [script I found.](https://github.com/FracKenA/fedora-coreos-proxmox/blob/master/vmsetup.sh) It's outdated, but full of hints.
