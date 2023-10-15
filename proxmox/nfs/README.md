Steps to install NFS server and allow local subnet access to /tank/share

```
apt-get install -y nfs-common nfs-kernel-server
echo "/tank/share       $(ip -o -f inet addr show | awk '/scope global/ {print $4}')(rw,fsid=0,crossmnt,insecure,subtree_check,async)" > /etc/exports
systemctl start nfs-kernel-server.service
```
