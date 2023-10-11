#!/bin/bash

DATE_STR=$(TZ='Asia/Hong_Kong' date +%Y-%m-%d)

if [ "$UID" -ne "0" ]; then
	echo "Must be run with root."
	exit 1
fi

if [ ! $PKG_PATH ]; then
    echo "Please set PKG_PATH first."
    exit 1
fi

PKG_PATH=$(readlink -f $PKG_PATH)
if [ ! -e $PKG_PATH ]; then
    echo "Error: '$PKG_PATH' is not exist."
    exit 1
fi

echo ""
echo "Package path: $PKG_PATH"
echo ""

echo "Info Step 1: Extracting Jetson_Linux_R32.7.1_aarch64.tbz2"
tar xpf $PKG_PATH/Jetson_Linux_R32.7.1_aarch64.tbz2

echo "Info Step 2: Extracting secureboot_R32.7.1_aarch64.tbz2"
tar xpf $PKG_PATH/secureboot_R32.7.1_aarch64.tbz2

echo "Info Step 3: Extracting tegra_linux_sample-root-filesystem_r32.7.1_aarch64.tbz2"
cd Linux_for_Tegra/rootfs/
tar xpf $PKG_PATH/tegra_linux_sample-root-filesystem_r32.7.1_aarch64.tbz2
cd ..

echo "Info Step 4: Extracting e-CAM50_CUNX_JETSON_L4T32.7.1_10-OCT-2023_R01.tar.gz"
tar xpf $PKG_PATH/e-CAM50_CUNX_JETSON_L4T32.7.1_10-OCT-2023_R01.tar.gz
cp -v ../res/e-CAM50_CUNX_JETSON_L4T32.7.1_10-OCT-2023_R01/install_binaries.sh e-CAM50_CUNX_JETSON_L4T32.7.1_10-OCT-2023_R01/
cp -v ../res/e-CAM50_CUNX_JETSON_L4T32.7.1_10-OCT-2023_R01/e-CAM50_CUNX_L4T32.7.1_JP4.6.1_JETSON-NANO-XAVIERNX-TX2NX_R01/TX2_XAVIER/Kernel/kernel_tegra194-p3668-all-p3509-0000_sigheader.dtb.encrypt bootloader/

echo "Info Working directory: `pwd`"

echo "Info Step 5: Run ./tools/l4t_flash_prerequisites.sh to prepare the environment"
./tools/l4t_flash_prerequisites.sh

echo "Info Step 6: Applying binaries"
./apply_binaries.sh

echo "Info Step 7: Making QSPI flash image"
#cp jetson-xavier-nx-devkit-emmc.conf jetson-xavier-nx-J202DA-qspi.conf
ADDITIONAL_DTB_OVERLAY_OPT="BootOrderNvme.dtbo"  BOARDID=3668 BOARDSKU=0001 FAB=301  BOARDREV=G.0 \
./tools/kernel_flash/l4t_initrd_flash.sh  \
-p "-c bootloader/t186ref/cfg/flash_l4t_t194_qspi_p3668.xml --no-systemimg" \
--no-flash --massflash 5 --network usb0 \
jetson-xavier-nx-devkit-emmc external

mkdir -p ../deploy
#mv mfi_jetson-xavier-nx-J202DA-qspi.tar.gz ../deploy/mfi_jetson-xavier-nx-J202DA-qspi-$DATE_STR.tar.gz
mv mfi_jetson-xavier-nx-devkit-emmc.tar.gz ../deploy/mfi_jetson-xavier-nx-J202DA-qspi-$DATE_STR.tar.gz

echo "Info Step 8: Modify rootfs"
mv e-CAM50_CUNX_JETSON_L4T32.7.1_10-OCT-2023_R01 rootfs/home/
sed -i "s/<SOC>/t194/g" rootfs/etc/apt/sources.list.d/nvidia-l4t-apt-source.list
mount --bind /sys ./rootfs/sys
mount --bind /dev ./rootfs/dev
mount --bind /dev/pts ./rootfs/dev/pts
mount --bind /proc ./rootfs/proc
cp ../res/qemu-aarch64-static rootfs/usr/bin/
cp ../res/rootfs_magic.sh rootfs
chroot rootfs /rootfs_magic.sh
umount ./rootfs/sys
umount ./rootfs/dev/pts
umount ./rootfs/dev
umount ./rootfs/proc
rm rootfs/rootfs_magic.sh
rm rootfs/usr/bin/qemu-aarch64-static

echo "Info Step 9: Making SSD image"
#cp jetson-xavier-nx-devkit-emmc.conf jetson-xavier-nx-J202DA-ssd.conf
sed -i "s/num_sectors=\"60604416\"/num_sectors=\"240000000\"/g" tools/kernel_flash/flash_l4t_nvme.xml
ADDITIONAL_DTB_OVERLAY_OPT="BootOrderNvme.dtbo"  BOARDID=3668 BOARDSKU=0001 FAB=301  BOARDREV=G.0 \
./tools/kernel_flash/l4t_initrd_flash.sh --external-device nvme0n1p1 \
-c tools/kernel_flash/flash_l4t_nvme.xml -S 80GiB \
-p "-c bootloader/t186ref/cfg/flash_l4t_t194_qspi_p3668.xml --no-systemimg" \
--no-flash  --massflash 5 --network usb0 \
jetson-xavier-nx-devkit-emmc external

#mv mfi_jetson-xavier-nx-J202DA-ssd.tar.gz ../deploy/mfi_jetson-xavier-nx-J202DA-ssd-$DATE_STR.tar.gz
mv mfi_jetson-xavier-nx-devkit-emmc.tar.gz ../deploy/mfi_jetson-xavier-nx-J202DA-nvme-$DATE_STR.tar.gz

echo ""
echo "Finished!!!"
echo ""
