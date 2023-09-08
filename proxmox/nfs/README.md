```
apt-get install -y nfs-common nfs-kernel-server
echo "/tank/share       $(ip -o -f inet addr show | awk '/scope global/ {print $4}')(rw,fsid=0,insecure,no_subtree_check,async)" > /etc/export
systemctl start nfs-kernel-server.service
```
