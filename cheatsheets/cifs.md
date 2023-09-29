#### mount cifs share from windows to linux using kerbose
sudo mount -t cifs -o user=$USER,cruid=$USER,sec=krb5,gid=$GID,uid=$UID //domain/path /home/path
