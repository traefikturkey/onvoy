## Notice
- - -
 - This works with real and FULL vm installs of Ubuntu server 22.04 as of 06/07/22
 - If you do docker in lxc then this is probably not the script for you

## Setup Docker Server
To run copy and paste the line below on a fresh ubuntu server setup
```
curl -s https://raw.githubusercontent.com/traefikturkey/onvoy/master/ubuntu/bash/docker_server_setup.sh?$(date +%s) | /bin/bash -s | tee docker_build.log
```

## Setup Node Exporter for Prometheus
```
curl -s https://raw.githubusercontent.com/traefikturkey/onvoy/master/ubuntu/bash/node_exporter_setup.sh?$(date +%s) | /bin/bash -s | tee node_exporter_build.log
```
