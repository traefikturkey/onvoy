### Links
https://linuxhint.com/journalctl-tail-and-cheatsheet/

### Systemctl commands
List failed services
```
sudo systemctl list-units --failed
sudo systemctl list-units --state failed
sudo systemctl list-units | grep -i failed
```

Test if is-failed
```
sudo systemctl is-failed {service-name-here}
sudo systemctl is-failed nginx.service

# no output just exit code
sudo systemctl is-failed --quiet {service-name-here}
```

Find status of systemd unit or service
```
sudo systemctl status {service-name}
sudo systemctl status ssh.service
sudo systemctl status nginx.service
```

Display all messages
```
journalctl
journalctl | grep 'error'
```

Show only kernel messages
```
journalctl -k
```

View live messages on screen as they appear
```
journalctl -f
```

How to view service specific messages only
```
journalctl -u {service-name-here}
journalctl -u ssh.service
journalctl -u vboxweb.service
```
