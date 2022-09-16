#!/bin/bash

cd /opt

curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest \
| grep "browser_download_url.*linux-amd64" \
| cut -d ":" -f 2,3 \
| tr -d \" \
| sudo wget -qi -

sudo mkdir -p /var/lib/node_exporter
sudo chown daemon /var/lib/node_exporter

dir="$(sudo find . -name "node_exporter-*.linux-amd64.tar.gz" | sed 's/\.tar\.gz//g')"
sudo tar -xvzf $dir.tar.gz

sudo cp "./$dir/node_exporter" "./node_exporter"
sudo rm -rf "$dir" $dir.tar.gz

sudo tee -a /etc/systemd/system/node_exporter.service >/dev/null <<'EOF'
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target
 
[Service]
User=daemon
ExecStart=/opt/node_exporter \
            --collector.diskstats.ignored-devices="^(dm-|ram|loop|fd|(h|s|v|xv)d[a-z]|nvme\\d+n\\d+p)\\d+$" \
            --collector.filesystem.ignored-mount-points="^/(dev|proc|sys|run|var/lib/(docker|lxcfs|nobody_tmp_secure))($|/)" \
            --collector.filesystem.ignored-fs-types="^(autofs|binfmt_misc|cgroup|configfs|debugfs|devpts|devtmpfs|fuse.*|hugetlbfs|mqueue|overlay|proc|procfs|pstore|rpc_pipefs|securityfs|sysfs|tracefs)$" \
            --collector.netdev.device-blacklist="^(lo|docker[0-9]|veth.+)$" \
            --collector.textfile.directory=/var/lib/node_exporter \
            --collector.conntrack \
            --collector.cpu \
            --collector.diskstats \
            --collector.filefd \
            --collector.filesystem \
            --collector.loadavg \
            --collector.meminfo \
            --collector.netdev \
            --collector.netstat \
            --collector.sockstat \
            --collector.stat \
            --collector.textfile \
            --collector.time \
            --collector.uname \
            --collector.vmstat \
            --no-collector.arp \
            --no-collector.bcache \
            --no-collector.bonding \
            --no-collector.buddyinfo \
            --no-collector.drbd \
            --no-collector.edac \
            --no-collector.entropy \
            --no-collector.hwmon \
            --no-collector.infiniband \
            --no-collector.interrupts \
            --no-collector.ipvs \
            --no-collector.ksmd \
            --no-collector.logind \
            --no-collector.mdadm \
            --no-collector.meminfo_numa \
            --no-collector.mountstats \
            --no-collector.nfs \
            --no-collector.nfsd \
            --no-collector.qdisc \
            --no-collector.runit \
            --no-collector.supervisord \
            --no-collector.systemd \
            --no-collector.tcpstat \
            --no-collector.timex \
            --no-collector.wifi \
            --no-collector.xfs \
            --no-collector.zfs
 
[Install]
WantedBy=default.target
EOF

sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter

if [ -x "$(command -v ufw)" ]; then
  sudo ufw allow from any to any port 9100 proto tcp
fi

cd ~
