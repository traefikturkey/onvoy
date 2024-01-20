# Debian 12 Bookworm
# NVIDIA drivers
## Repo
### Add non-free repo to /etc/apt/sources.list

`echo "deb http://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware" >> /etc/apt/sources/list`

### 

## Install NVIDIA drivers
`LINUX_HEADERS=$(uname -r)`

`sudo apt update`

`sudo apt -y install nvidia-driver firmware-misc-nonfree linux-headers-$LINUX_HEADERS dkms`

This takes a bit.  Be patient

## verify driver usage

`cat /etc/modprobe.d/nvidia-blacklists-nouveau.conf`

Should look lke this:

```
# You need to run "update-initramfs -u" after editing this file.

# see #580894
blacklist nouveau
```

## CUDA
* THIS ASSUMES YOU ALREAD DID AN `SUDO APT UPDATE` *
### CUDA install

`sudo apt install nvidia-cuda-toolkit -y`

NVIDIA CUDA and the required dependency packages are being downloaded. It takes a while to complete

### CUDA verification
`nvcc --version`

## CuDNN
`sudo apt install nvidia-cudnn -y`

Select `I Agree` and select `OK`

# Verify NVIDIA driver installation

Run the command `nvidia-smi`

If you receive the error, `NVIDIA-SMI has failed because it couldn't communicate with the NVIDIA driver. Make sure that the latest NVIDIA driver is installed and running.`, it means you need to reboot to use the drivers.