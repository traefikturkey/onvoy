#### on alpine
https://serverfault.com/questions/1131671/how-can-i-send-dns-resource-record-updates-from-linux-to-a-windows-active-direct

```
sudo apk add nsupdate bind-tools krb5
sudo nano /etc/krb5.conf
```

```
[realms]
CORP.EXAMPLE.LOCAL = {
  kdc = ms-dc-01.corp.example.local:88
  kdc = ms-dc-02.corp.example.local:88
  admin_server = ms-dc-01.corp.example.local
  default_domain = corp.example.local
}
```

```
kinit administrator@corp.example.local
klist
nsupdate
```

```
gsstsig
server chicago-dns-14.corp.example.local
zone corp.example.local.
update add my-new-test-record.corp.example.local. 3600 A 1.1.1.1
show
send
quit
```
