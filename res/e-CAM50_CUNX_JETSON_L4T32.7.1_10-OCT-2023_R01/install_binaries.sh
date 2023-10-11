#!/bin/bash
#   Copyright (c) 2016-2019, e-con Systems India Pvt. Ltd. All rights reserved.
#
#   Script to update the Kernel Binaries and packages required in target board
#

#!/bin/bash
#LOG_LOCATION=/home/nvidia/logs/

init ()
{
	exec > >(tee  binary_installation_log.txt) 2>&1
	trap chk_exit_status ERR EXIT
	set -eu
	MAX_PLATFORMS=5 # Current platforms supported: NANO, TX2, TX2-NX, XAVIER, XAVIER NX
	PLATFORMS=()
	echo "============================================="
	echo " Running E-CON Installation Script "
	echo " DATE : $(date)         "
	echo "============================================="

}

chk_exit_status ()
{
	ERR_CODE=$?
	if [ $ERR_CODE -ne 0 ]; then
		echo "Installation failed on ${FUNCNAME[1]} function at line no $(echo $(caller) | cut -d' ' -f1) with error code $ERR_CODE";
		exit 1;
	fi
}
print_release_details ()
{
	i=1;
	RELEASE_PKG_NAME="$(echo $file_name | cut -d":" -f1)";
	L4T_VERSION="$(echo $RELEASE_PKG_NAME | cut -d"_" -f3)";
	JETPACK_VER="$(echo $RELEASE_PKG_NAME | cut -d"_" -f4)";
	JETSON_PLATFORM="$(echo $RELEASE_PKG_NAME | cut -d"_" -f5)";
	while [ $i -le $MAX_PLATFORMS ]
	do
		i=`expr $i + 1`;
		CUR_PLATFORM=$(echo $JETSON_PLATFORM | cut -d"-" -f$i);
		if [ "$CUR_PLATFORM" != "" ]
		then
			PLATFORMS+=(jetson-${CUR_PLATFORM,,});
		fi
	done
	unset i;
	NO_OF_PLATFORMS=${#PLATFORMS[@]};
	RELEASE_VERSION="$(echo $RELEASE_PKG_NAME | cut -d"_" -f6 | cut -d"." -f1)";
	echo " Release Package Details :
	Release Package Name is $RELEASE_PKG_NAME
	L4T Version is $L4T_VERSION
	Jetpack Version is $JETPACK_VER
	Jetson Platforms: ${PLATFORMS[*]}
	Release Version is $RELEASE_VERSION"
}
prerequisites ()
{
	# 1. Confirm root permission to execute script
	if [[ $EUID -ne 0 ]] ; then
		echo "Kindly relaunch the script with root user privilege";
		exit 1;
	else
		echo "Running this script as root";
		echo "continue ......";
	fi

	# 2. Check integrity using md5sum
	if [ ! -e $PWD/release_integrity.md5 ] ; then
		echo "Release checksum file missing ...";
		echo "Exitting ......";
		exit 1;
	fi
	file_name=$(md5sum -c release_integrity.md5);
	if [ ! -e $PWD/$(echo $file_name | cut -d":" -f1) ] ; then
		echo "Release Package file missing ...";
		echo "Exitting ......";
		exit 1;
	fi

	# Function to print release package information
	print_release_details

	# Read L4T version onboard
	if [ -e /etc/nv_tegra_release ] ; then
		JETSON_L4T_STRING=$(cat /etc/nv_tegra_release | head -n 1 | cut -d',' -f1-2 | awk ' {print $2,$5} ' | sed 's/ /./g' | sed 's/'R'/L4T/g');
	else
		JETSON_L4T_STRING="L4T$(dpkg-query --showformat='${Version}' --show nvidia-l4t-core | cut -d'-' -f1)"
	fi

	if [ -e /etc/nv_boot_control.conf ] ; then
		CURRENT_PLATFORM_CHIPID=$(cat /etc/nv_boot_control.conf | grep "TEGRA_CHIPID" | cut -d" " -f2);
	else
		echo "/etc/nv_boot_control.conf File Missing , Exitting";
		exit 1;
	fi

	# Exit if /proc/device-tree/model is missing
	# if [ ! -e /proc/device-tree/model ]; then
	#    echo "/proc/device-tree/model File Missing, Exitting shell script";
	#    exit 1;
	# fi
	#model=$(tr -d '\0' </proc/device-tree/model);
	model="NVIDIA Jetson Xavier NX Developer Kit"
	if [ $CURRENT_PLATFORM_CHIPID == "0x21" ] ; then
		#model=$(tr -d '\0' </proc/device-tree/model);
		model="NVIDIA Jetson Xavier NX Developer Kit"
		if [[ ${model,,} =~ "nano" ]] ; then
			CURRENT_PLATFORM="jetson-nano";
		else
			CURRENT_PLATFORM="jetson-tx1";
		fi
	elif [ $CURRENT_PLATFORM_CHIPID == "0x18" ] ; then
		if [[ ${model,,} =~ "lanai" ]] ; then
			CURRENT_PLATFORM="jetson-tx2nx";
		else
			CURRENT_PLATFORM="jetson-tx2";
		fi
	elif [ $CURRENT_PLATFORM_CHIPID == "0x19" ] ; then
		if [[ ${model,,} =~ "nx" ]] ; then
			CURRENT_PLATFORM="jetson-xaviernx";
		else
			CURRENT_PLATFORM="jetson-xavier";
		fi
	
	else
		echo "$CURRENT_PLATFORM is not supported";
		echo "Exitting";
		exit 1;
	fi

	# 3. Confirm L4T version and Platform details of current board , where script is running
	if [ $(uname -m) != "aarch64" ] ; then
		echo "Machine architecture mismatched, Exiting release package installation process";
		exit 1;
	else
		echo "Machine architecture matched";
	fi

	if [ $L4T_VERSION != "$JETSON_L4T_STRING" ] ; then
		echo "Device L4T version $JETSON_L4T_STRING mismatched with release package L4T version $L4T_VERSION , Exiting release package installation process";
		exit 1;
	else
		echo "L4T Version matched ";
	fi

	for i in ${PLATFORMS[@]}
	do
		if [  "$i" == "$CURRENT_PLATFORM" ] ; then
			echo "Jetson Platform matched $i";
			JETSON_PLATFORM=$i;
			return 0;
		fi
	done

	echo "Device platform $CURRENT_PLATFORM mismatched with release package. Exiting release package installation process";
	exit 1;
}

update_kernel () {
	echo "Created folder for Image backup";
	mkdir -p $HOME/Images_Backup;
	# Update kernel based on the platform decided
	if [ $JETSON_PLATFORM == "jetson-nano" ] || [ $JETSON_PLATFORM == "jetson-tx2" ] || [ $JETSON_PLATFORM == "jetson-tx2nx" ] || [ $JETSON_PLATFORM == "jetson-xavier" ] || [ $JETSON_PLATFORM == "jetson-xaviernx" ]; then
		echo "Taking backup of Kernel Image";
		cp /boot/Image $HOME/Images_Backup/;
		echo "Copying Image to device";
		cp $EXTRACTED_PATH/Kernel/Image /boot/;
		if [ $(md5sum /boot/Image | cut -d " " -f1) == $(md5sum $EXTRACTED_PATH/Kernel/Image | cut -d " " -f1) ] ; then
			echo "Kernel image updated successfully";
		else
			echo "Kernel image updated failed";
			echo "Exitting";
			exit 1;
		fi
	else
		echo "Kernel image updated failed";
		echo "Exitting";
		exit 1;
	fi
}
update_devicetree () {
	# Update device tree based on the platform decided
	echo "Extracting device tree name and dtb block device to flash"
	# TBD : Have to handle multiple DTB's scenario
	if [ $JETSON_PLATFORM == "jetson-nano" ] ; then
		JN_REV=$(i2cget -f -y 2 0x50 0x23)

		if [ $JN_REV == "0x34" ] ; then
			echo "Board Revision is Jetson Nano B00";
			DTB_NAME=$(basename $(find $PWD/$EXTRACTED_PATH/Kernel/B00/ -iname tegra210*));
		elif [ $JN_REV == "0x32" ] ; then
			echo "Board Revision is Jetson Nano A02";
			DTB_NAME=$(basename $(find $PWD/$EXTRACTED_PATH/Kernel/A02/ -iname tegra210*));
		else
			echo "BOARD revision not supported by e-con System presently";
			echo "Supported Jetson Nano revisions are A02, B00";
			echo "Exiting";
			exit 1;
		fi

		DTB_DEVICE=/dev/mtdblock0;
	elif [ $JETSON_PLATFORM == "jetson-tx2" ] ; then
		DTB_NAME=$(basename $(find $PWD/$EXTRACTED_PATH/Kernel/ -iname tegra186*));
		DTB_DEVICE=$(readlink -f /dev/disk/by-partlabel/kernel-dtb);
	elif [ $JETSON_PLATFORM == "jetson-tx2nx" ] ; then
	    	DTB_NAME=$(basename $(find $PWD/$EXTRACTED_PATH/Kernel/ -iname tegra186*));
	    	DTB_DEVICE=$(readlink -f /dev/disk/by-partlabel/kernel-dtb);
	elif [ $JETSON_PLATFORM == "jetson-xavier" ] ; then
		DTB_NAME=$(basename $(find $PWD/$EXTRACTED_PATH/Kernel/ -iname tegra194-p2888*));
		DTB_DEVICE=$(readlink -f /dev/disk/by-partlabel/kernel-dtb);
	elif [ $JETSON_PLATFORM == "jetson-xaviernx" ] ; then
		DTB_NAME=$(basename $(find $PWD/$EXTRACTED_PATH/Kernel/ -iname kernel_tegra194-p3668*));
		DTB_DEVICE=$(readlink -f /dev/disk/by-partlabel/kernel-dtb);
		DTB_DEVICE_B=$(readlink -f /dev/disk/by-partlabel/kernel-dtb_b);
	fi
	
	if [ $JETSON_PLATFORM == "jetson-nano" ] ; then
		echo "Taking backup of device-tree";
		dd if=$DTB_DEVICE of=$HOME/Images_Backup/Backup_dtb.encrypt skip=4992 bs=512 count=640;
		echo "Flashing device tree to board";
		if [ $JN_REV == "0x34" ] ; then
			dd if=$EXTRACTED_PATH/Kernel/B00/$DTB_NAME of=$DTB_DEVICE seek=4992 bs=512;
		else
			dd if=$EXTRACTED_PATH/Kernel/A02/$DTB_NAME of=$DTB_DEVICE seek=4992 bs=512;
		fi
	else
		echo "Taking backup of device-tree";
		dd if=$DTB_DEVICE of=$HOME/Images_Backup/Backup_dtb.encrypt bs=1M;
		echo "Flashing device tree to board";
		dd if=$EXTRACTED_PATH/Kernel/$DTB_NAME of=$DTB_DEVICE bs=1M;
		if [ $JETSON_PLATFORM == "jetson-xaviernx" ] ; then
			dd if=$EXTRACTED_PATH/Kernel/$DTB_NAME of=$DTB_DEVICE_B bs=1M;
		fi
	fi
	echo "Device Tree updated successfully";
}
update_modules () {
	echo "extracting modules to rootfs";
	sudo tar -xpmf $EXTRACTED_PATH/Kernel/kernel_supplements.tar.bz2 -C /lib
	echo "Modules updated successfully";
}
application_installation ()
{

	if [ -d $EXTRACTED_PATH/Application/Binaries/eCAM_argus_camera/ ] ; then
		ISP_PRD="yes";
	else
		ISP_PRD="no";
	fi

	# 1. Install deb packages
	if [ -d $EXTRACTED_PATH/Application/Dependency/ ] ; then
		echo "Install Debian Packages";
		if [ $ISP_PRD == "no" ]; then
			rm -f /var/lib/dpkg/lock*
			sudo dpkg --remove --force-all libjack-jackd2-0:arm64
		fi
		pushd $EXTRACTED_PATH/Application/Dependency/
		rm -f /var/lib/dpkg/lock*
		sudo dpkg -i --force-all *.deb
		echo " Application dependency Installed Successfully"
		popd
	fi

	# 2. Copy Application Binaries to rootfs

	if [ $ISP_PRD == "yes" ] ; then
		echo "Installing eCAM_argus_camera Application Binary for ISP camera";
		cp $EXTRACTED_PATH/Application/Binaries/eCAM_argus_camera/* /usr/local/bin/

		if [ -d $EXTRACTED_PATH/Application/Binaries/eCAM_Argus_MultiCamera/ ] ; then
			echo "Installing eCAM_Argus_MultiCamera Application Binary for ISP camera";
			cp $EXTRACTED_PATH/Application/Binaries/eCAM_Argus_MultiCamera/* /usr/local/bin/
		fi
	else
		echo "Installing ecam_tk1_guvcview Application for non-isp cameras";
		pushd $EXTRACTED_PATH/Application/Binaries/ecam_tk1_guvcview/aarch64
		sudo ./install-sh
		# Remove older configuration files for guvcview
		rm -rf $HOME/.config/guvcview/
		#echo 'export PATH=$PATH:/usr/local/ecam_tk1/bin' >> $HOME/.bashrc
		#source $HOME/.bashrc
		popd

		if [ -d $EXTRACTED_PATH/Application/Binaries/e-multicam/ ] ; then
			echo "Installing e-multicam Application for non-isp cameras";
			cp $EXTRACTED_PATH/Application/Binaries/e-multicam/e-multicam.elf /usr/local/bin/
		fi
	fi
}

package_extraction () {
	if [ -e $RELEASE_PKG_NAME ] ; then
		EXTRACTED_PATH=$(echo $RELEASE_PKG_NAME | cut -d"." -f-5);
		if [ -d $EXTRACTED_PATH ] ; then
			echo "Delete already extracted package and redo package extraction";
			rm -rf $EXTRACTED_PATH
		fi
		echo "Extracting release package"
		tar -xmf $RELEASE_PKG_NAME
	fi

	if [ $JETSON_PLATFORM == "jetson-nano" ] ; then
		EXTRACTED_PATH=$EXTRACTED_PATH/NANO
	elif [ $JETSON_PLATFORM == "jetson-tx2nx" ]; then
		EXTRACTED_PATH=$EXTRACTED_PATH/TX2_NX
	elif [ $JETSON_PLATFORM == "jetson-tx2" ] || [ $JETSON_PLATFORM == "jetson-xavier" ] || [ $JETSON_PLATFORM == "jetson-xaviernx" ]
	then
		EXTRACTED_PATH=$EXTRACTED_PATH/TX2_XAVIER
	fi
}

misc_installation () {
	echo "Updating misc files";
	if [ $ISP_PRD = "yes" ] ; then
		if [ -e $EXTRACTED_PATH/misc/camera_overrides_$JETSON_PLATFORM.isp ] ; then
			echo "Copy ISP settings to rootfs /var/nvidia/nvcam/settings ";
			cp $EXTRACTED_PATH/misc/camera_overrides_$JETSON_PLATFORM.isp /var/nvidia/nvcam/settings/camera_overrides.isp;
			echo "permissions and ownerships as recommended by nvidia for isp_settings file";
			chmod 664 /var/nvidia/nvcam/settings/camera_overrides.isp;
			chown root:root /var/nvidia/nvcam/settings/camera_overrides.isp;
		else
			echo "ISP overrides file missing. Exiting";
			exit 1;
		fi

		if [ -e $EXTRACTED_PATH/misc/libnvscf.so ] ; then
			echo "Update nvscf library ";
			cp $EXTRACTED_PATH/misc/libnvscf.so /usr/lib/aarch64-linux-gnu/tegra/libnvscf.so;
			echo "permissions and ownerships as recommended by nvidia for library file";
			chmod 755 /usr/lib/aarch64-linux-gnu/tegra/libnvscf.so;
			chown root:root /usr/lib/aarch64-linux-gnu/tegra/libnvscf.so;
		fi

		if [ -e $EXTRACTED_PATH/misc/max-isp-vi-clks.sh ] ; then
			echo "Copy max-isp-vi-clks.sh script for isp camera"
			cp $EXTRACTED_PATH/misc/max-isp-vi-clks.sh $HOME/ -f
			chmod +x $HOME/max-isp-vi-clks.sh
		fi
	else
		if [ $JETSON_PLATFORM == "jetson-xavier" ] ; then
			if [ -e $EXTRACTED_PATH/misc/xorg.conf.t194_ref ] ; then
				echo "Copying updated xorg.conf.t194_ref file";
				cp $EXTRACTED_PATH/misc/xorg.conf.t194_ref /etc/X11/;
			fi
		elif [ $JETSON_PLATFORM == "jetson-tx2" ] ; then
			if [ -e $EXTRACTED_PATH/misc/xorg.conf ] ; then
				echo "Copying updated xorg.conf file";
				cp $EXTRACTED_PATH/misc/xorg.conf /etc/X11/;
			fi
		fi
	fi
	if [ -e $EXTRACTED_PATH/misc/modules ] ; then
		echo "copying updated /etc/modules file for e-con camera driver onboot load process";
		cp $EXTRACTED_PATH/misc/modules /etc/;
	fi
	echo " Updated misc files successfully";

}
device_reboot() {
	echo "Sync 'ing : writing cached data to disk";
	sync;
	echo "Going to reboot the device ....";
	sleep 5;
	echo "Rebooting the device .....";
	reboot;

}

usage() {
	echo -e "usage: $0 [options]..."
    	echo -e "update kernel, DTB, modules and install binary packages\n"
    	echo -e "-d\t-\tDTB overwrite (optional)\n"
}

if [ $# -lt 1 ]
then
	init
	#1. Sanity check
   	prerequisites
    	#2. Release package extraction
    	package_extraction
    	#3. Kernel Binaries Installation
    	update_kernel
    	#update_devicetree
    	update_modules
    	#4. Application Binaries Installation
    	application_installation;
    	#5. Miscellenaous file upgrades for e-con cameras
    	misc_installation;
    	#6. Rebooting device to boot with installed binaries
    	device_reboot
    	exit 0
fi

while getopts 'd?h' opt
do
    case $opt in
        
        d)
		init
		#1. Sanity check
	   	prerequisites
	    	#2. Release package extraction
	    	package_extraction
	    	#3. Kernel Binaries Installation
	    	#update_devicetree
	    	#4. Rebooting device to boot with changed DTB
	    	device_reboot

	    ;;
	h|?) usage; exit 2 ;;
    esac
done

shift "$((OPTIND - 1))"
