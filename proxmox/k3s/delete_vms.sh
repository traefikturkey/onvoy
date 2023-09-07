#!/bin/bash

# curl -s "https://raw.githubusercontent.com/traefikturkey/onvoy/master/proxmox/bash/k3s/delete_vms.sh?$(date +%s)" | /bin/bash -s

qm stop 201
qm stop 202
qm stop 203
qm stop 211
qm stop 212

qm destroy 201 --destroy-unreferenced-disks --purge
qm destroy 202 --destroy-unreferenced-disks --purge
qm destroy 203 --destroy-unreferenced-disks --purge
qm destroy 211 --destroy-unreferenced-disks --purge
qm destroy 212 --destroy-unreferenced-disks --purge
