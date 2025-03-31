## Notice
- - -
 - This works with real and FULL vm installs of Ubuntu server 22.04 as of 06/07/22
 - If you do docker in lxc then this is probably not the scriptz for you
 - To run copy and paste the line below on a fresh ubuntu server setup

## Setup Base Server 
```
curl -s https://raw.githubusercontent.com/traefikturkey/onvoy/refs/heads/main/ubuntu/bash/base_server_setup.sh?$(date +%s) | /bin/bash -s | tee docker_build.log
```

## Setup Docker Server
```
curl -s https://raw.githubusercontent.com/traefikturkey/onvoy/master/ubuntu/bash/docker_server_setup.sh?$(date +%s) | /bin/bash -s | tee docker_build.log
```

## Setup Node Exporter for Prometheus
```
curl -s https://raw.githubusercontent.com/traefikturkey/onvoy/master/ubuntu/bash/node_exporter_setup.sh?$(date +%s) | /bin/bash -s | tee node_exporter_build.log
```

## Setup Podman
```
curl -s https://raw.githubusercontent.com/traefikturkey/onvoy/refs/heads/main/ubuntu/bash/podman_server_setup.sh?$(date +%s) | /bin/bash -s | tee podman_build.log
```
