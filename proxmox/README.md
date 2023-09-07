### Here are some helpful proxmox notes and setup scripts.
- - -
The bash version is [here](https://github.com/traefikturkey/onvoy/blob/master/proxmox/bash/setup.sh) and can be used by running the following command:
```
curl -s https://raw.githubusercontent.com/traefikturkey/onvoy/master/proxmox/bash/setup.sh?$(date +%s) | /bin/bash -s
```

#### [Notes](/traefikturkey/onvoy/blob/master/proxmox/notes) Section
- - - 
this section contains configuration files and commands that are used to setup things, it should be considered alpha quality code as its has not been tested as much!

other scripts for proxmox can be found here: [https://tteck.github.io/Proxmox/](https://tteck.github.io/Proxmox/)

Notes about Debian 12 Bookworm: [https://www.debian.org/releases/bookworm/amd64/release-notes/ch-information.html#non-free-split](https://www.debian.org/releases/bookworm/amd64/release-notes/ch-information.html#non-free-split)

https://bobcares.com/blog/proxmox-cant-stop-vm/

Cloudinit Notes:

https://gist.github.com/KrustyHack/fa39e509b5736703fb4a3d664157323f
https://pve.proxmox.com/wiki/Cloud-Init_Support
https://pve.proxmox.com/wiki/Cloud-Init_FAQ
https://georgev.design/blog/create-proxmox-cloud-init-templates
https://austinsnerdythings.com/2021/08/30/how-to-create-a-proxmox-ubuntu-cloud-init-image/
https://github.com/piku/cloud-init/blob/master/README.md

#### Use the Source Luke
- - -
Some of the code and notes here originally came from [iLude's Gist](https://gist.github.com/ilude/32aec45964bc1207810f7e6e49544064) but is now being fully maintained here!

### Odds and Ends
https://forum.proxmox.com/threads/mount-host-directory-into-lxc-container.66555/
```
pct set 103 -mp0 /host/dir,mp=/container/mount/point
```

#### nfs notes
```
sudo apt-get install -y nfs-common nfs-kernel-server
sudo echo "/tank/share       192.168.16.0/24(rw,fsid=0,insecure,no_subtree_check,async)" > /etc/export
systemctl start nfs-kernel-server.service
```

#### unattended upgrades
https://wiki.debian.org/UnattendedUpgrades

#### setup gmail email sending 
https://geekistheway.com/2021/03/07/configuring-e-mail-alerts-on-your-proxmox/
