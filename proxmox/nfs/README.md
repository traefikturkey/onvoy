Steps to install NFS server and allow local subnet access to /tank/share

```
export NFS_SHARE_PATH=/tank/share
apt-get install -y nfs-common nfs-kernel-server
echo "${NFS_SHARE_PATH}       $(ip -o -f inet addr show | awk '/scope global/ {print $4}')(rw,fsid=0,crossmnt,insecure,subtree_check,async,anonuid=1000,anongid=1000)" > /etc/exports
chown 1000:1000 ${NFS_SHARE_PATH}
chmod 775 ${NFS_SHARE_PATH}
systemctl start nfs-kernel-server.service
```
