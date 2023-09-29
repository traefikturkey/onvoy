#### mount cifs share from windows to linux using kerbose
https://superuser.com/questions/1082450/mount-a-samba-share-using-kerberos-ticket/1241316#1241316

```
sudo mount -t cifs -o user=$USER,cruid=$USER,sec=krb5,gid=$GID,uid=$UID //domain/path /home/path
```
