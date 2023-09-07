```
zfs set atime=off <pool_name>
zfs set compression=lz4 <pool_name>

zpool add <pool_name> cache <device_name_from_lsblk>
zpool add <pool_name> log mirror c4t1d0 c4t2d0

zfs create pool/share
zfs create pool/share/apps 
zfs create pool/share/iso
zfs create pool/share/media
zfs create pool/vmstorage 

zfs list

NAME                           USED  AVAIL     REFER  MOUNTPOINT
pool                          24.4G  8.19T      192K  /pool
pool/share                    24.4G  8.19T      224K  /pool/share
pool/share/apps               23.0G  8.19T     23.0G  /pool/share/apps
pool/share/iso                1.37G  8.19T     1.37G  /pool/share/iso
pool/share/media               192K  8.19T      192K  /pool/share/media
pool/vmstorage                 304K  8.19T      192K  /pool/vmstorage
```

Back in GUI land…

Click on “Datacenter”
“Storage”
“Add”
“Directory”
ID: iso
Directory: /storage/share/iso
Content: make sure only “ISO image” and “Container template” are selected.
“Add”

And again…
“Add”
“ZFS”
ID: vmstorage
ZFS Pool: /storage/vmstorage

