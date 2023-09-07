# barrowed from https://github.com/DeadlockState/Proxmox-prepare/blob/master/proxmox_prepare.sh

apt-get install -y fail2ban > /dev/null 2>&1
	
cd /etc/fail2ban/

touch jail.local

echo "[proxmox]
enabled = true
port = http,https,8006
filter = proxmox
logpath = /var/log/daemon.log
maxretry = 4
bantime = 43200" > jail.local

cd filter.d/

touch proxmox.conf

echo "[Definition]
failregex = pvedaemon\[.*authentication failure; rhost=<HOST> user=.* msg=.*
ignoreregex =" > proxmox.conf

sysstemctl restart fail2ban.service
