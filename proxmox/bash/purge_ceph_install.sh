# copy and paste oneliner below to run
# curl -s https://raw.githubusercontent.com/traefikturkey/onvoy/master/proxmox/bash/purge_ceph_install.sh?$(date +%s) | /bin/bash -s

# These commands will nuke the proxmox ceph install and allow you to reinstall
# https://forum.proxmox.com/threads/how-to-clean-up-a-bad-ceph-config-and-start-from-scratch.68949/post-310629

rm -rf /etc/systemd/system/ceph*
killall -9 ceph-mon ceph-mgr ceph-mds
rm -rf /var/lib/ceph/mon/  /var/lib/ceph/mgr/  /var/lib/ceph/mds/
pveceph purge
apt -y purge ceph-mon ceph-osd ceph-mgr ceph-mds
rm /etc/init.d/ceph
for i in $(apt search ceph | grep installed | awk -F/ '{print $1}'); do apt reinstall $i; done
dpkg-reconfigure ceph-base
dpkg-reconfigure ceph-mds
dpkg-reconfigure ceph-common
dpkg-reconfigure ceph-fuse
for i in $(apt search ceph | grep installed | awk -F/ '{print $1}'); do apt reinstall $i; done
apt autoremove -y
