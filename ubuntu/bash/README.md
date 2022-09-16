## Notice
- - -
 - This works with real and FULL vm installs of Ubuntu server 22.04 as of 06/07/22
 - If you do docker in lxc then this is probably not the script for you

To run copy and paste the line below on a fresh ubuntu server setup
```
curl -s https://raw.githubusercontent.com/traefikturkey/onvoy/master/ubuntu/bash/setup.sh?$(date +%s) | /bin/bash -s | tee build.log
```
