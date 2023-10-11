 #!/bin/bash
echo 'Acquire::http::Proxy "http://192.168.1.77:3142";' >> /etc/apt/apt.conf

apt-get update
apt install -y nvidia-jetpack pulseaudio-module-bluetooth
systemctl disabled nvgetty.service
apt-get clean
depmod -a
rm /etc/apt/apt.conf

cd /home/e-CAM50_CUNX_JETSON_L4T32.7.1_10-OCT-2023_R01
./install_binaries.sh
cd ../
rm -rf e-CAM50_CUNX_JETSON_L4T32.7.1_10-OCT-2023_R01