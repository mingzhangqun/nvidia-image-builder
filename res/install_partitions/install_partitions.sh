#!/bin/bash

if [ "$UID" -ne "0" ]; then
	echo "Must be run with root."
	exit 1
fi

if [ "$1" == "" ]; then
	echo "Must specifie a disk like '/dev/sdX'."
	exit 1
fi

if [ ! -e $1 ]; then
    echo "Error: '$1' is not exist."
    exit 1
fi

echo ""
echo "**************************************************"
echo "* All data on the disk '$1' will be erased *"
echo "**************************************************"
read -p "Are you sure? [y/N]" -n 1 -r input
echo ""

case $input in
    [yY][eE][sS]|[yY])
        # echo "Continue..."
        ;;
 
    # [nN][oO]|[nN])
    #     echo "Operation terminated!!!"
    #     exit 1
    #        ;;
 
    *)
        echo "Operation terminated!!!"
        exit 1
        ;;
esac

echo "Creating partitions..."
sgdisk -Z $1
sgdisk -n "0:0:80G" -c 0:"APP" -t 0:"0700" -u "0:d469d30f-38ba-4ec3-af99-baad598070b4" $1
sgdisk -n "0:0:+64M" -c 0:"kernel" -t 0:"0700" -u "0:64154858-d1a1-430b-a10c-3712ad3b1b7d" $1
sgdisk -n "0:0:+64M" -c 0:"kernel_b" -t 0:"0700" -u "0:45fdf448-2d42-468a-ba2c-335e7bf1204b" $1
sgdisk -n "0:0:+512K" -c 0:"kernel-dtb" -t 0:"0700" -u "0:784157e1-d3d1-4512-8d48-9768ec113247" $1
sgdisk -n "0:0:+512K" -c 0:"kernel-dtb_b" -t 0:"0700" -u "0:66cf7b40-abcd-43a8-9539-67521aef7d17" $1
sgdisk -n "0:0:+64M" -c 0:"recovery" -t 0:"0700" -u "0:3148a0b9-0202-4504-8bf7-863b14c5c835" $1
sgdisk -n "0:0:+512K" -c 0:"recovery-dtb" -t 0:"0700" -u "0:38cc5c66-d304-4aa2-bb1f-c05d774aa969" $1
sgdisk -n "0:0:+256K" -c 0:"kernel-bootctrl" -t 0:"0700" -u "0:0768e0a8-f4b8-46e2-842e-b00f9e548f3e" $1
sgdisk -n "0:0:+256K" -c 0:"kernel-bootctrl_b" -t 0:"0700" -u "0:4dc31257-904b-42d8-a1dd-3f0cb05ad831" $1
sgdisk -n "0:0:+300M" -c 0:"RECROOTFS" -t 0:"0700" -u "0:75e461ec-e983-4e76-9d96-f32e3456e23b" $1
sgdisk -n "0:0:0" -c 0:"UDA" -t 0:"0700" -u "0:150116c5-c297-4d26-af47-0307a66e420d" $1

dd if=/dev/zero of=/dev/sdb1 bs=100M count=1
dd if=/dev/zero of=/dev/sdb9 bs=1K count=256

mkfs.ext4 /dev/sdb1 -U 1ab482b2-d58c-4c80-81bf-276a559917f2
mkfs.ext4 /dev/sdb9 -U b2273843-faf9-4fa2-8a41-edd71b095562

#tune2fs /dev/sdb1 -U 1ab482b2-d58c-4c80-81bf-276a559917f2
#tune2fs /dev/sdb9 -U b2273843-faf9-4fa2-8a41-edd71b095562

echo "Extracting rootfs..."
mkdir -p app
mount /dev/sdb1 app
tar xpf ./parts/app.tar.gz -C .
umount app
rm -rf app

echo "Writing other partitions..."
dd if=./parts/p2.img of=/dev/sdb2
dd if=./parts/p3.img of=/dev/sdb3
dd if=./parts/p4.img of=/dev/sdb4
dd if=./parts/p5.img of=/dev/sdb5
dd if=./parts/p6.img of=/dev/sdb6
dd if=./parts/p7.img of=/dev/sdb7
dd if=./parts/p8.img of=/dev/sdb8
dd if=./parts/p10.img of=/dev/sdb10

sync
echo "Finished!!!"
echo ""