#!/bin/bash

qm clone 9000 201 --name k3s-manager-1 --full false
qm clone 9000 202 --name k3s-manager-2 --full false
qm clone 9000 203 --name k3s-manager-3 --full false
qm clone 9000 211 --name k3s-worker-1 --full false
qm clone 9000 212 --name k3s-worker-2 --full false

qm set 201 --memory 8192
qm resize 201 scsi0 +16G

qm set 202 --memory 8192
qm resize 202 scsi0 +16G

qm set 203 --memory 8192
qm resize 203 scsi0 +16G

qm set 211 --memory 16384
qm resize 211 scsi0 +64G

qm set 212 --memory 16384
qm resize 212 scsi0 +64G

qm start 201
qm start 202
qm start 203
qm start 211
qm start 212
