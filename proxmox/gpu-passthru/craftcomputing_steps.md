https://www.youtube.com/watch?v=_hOBAGKLQkI

ProxMox Setup for PCIe Passthrough

-Legacy Systems; Add IOMMU Support-

nano /etc/default/grub
GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on"
	- OR -
GRUB_CMDLINE_LINUX_DEFAULT="quiet amd_iommu=on"

Save file and close

update-grub


-EFI Boot Systems; Add IOMMU Support-

nano /etc/kernel/cmdline
%> intel_iommu=on
    - OR -
%> amd_iommu=on

Save file and close

proxmox-boot-tool refresh


-Load VFIO modules at boot-

nano /etc/modules

vfio
vfio_iommu_type1
vfio_pci
vfio_virqfd

Save file and close


-Blacklist graphic drivers (optional)-

echo "options vfio_iommu_type1 allow_unsafe_interrupts=1" > /etc/modprobe.d/iommu_unsafe_interrupts.conf
echo "options kvm ignore_msrs=1" > /etc/modprobe.d/kvm.conf

echo "blacklist nouveau" >> /etc/modprobe.d/blacklist.conf
echo "blacklist nvidia" >> /etc/modprobe.d/blacklist.conf

-Configure GPU for PCIe Passthrough-

	- Find your GPU
lspci

	- Enter the PCI identifier
lspci -n -s 82:00 -v

	- Copy the HEX values from your GPU here:
echo "options vfio-pci ids=####.####,####.#### disable_vga=1"> /etc/modprobe.d/vfio.conf


-Apply all changes-

update-initramfs -u -k all

--REBOOT--
