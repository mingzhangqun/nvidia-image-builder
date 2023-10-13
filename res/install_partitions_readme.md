# 1. System is configured & e-CAM50 pre-installed

## Step 1: Roll back qspi to R32.7.1

```bash
seeed@ubuntu:~/$ tar xpf mfi_jetson-xavier-nx-J202DA-qspi-2023-10-11.tar.gz
seeed@ubuntu:~/$ cd mfi_jetson-xavier-nx-J202DA-qspi-2023-10-11/
seeed@ubuntu:~/mfi_jetson-xavier-nx-J202DA-qspi-2023-10-11$ sudo ./tools/kernel_flash/l4t_initrd_flash.sh --flash-only
```

## Step 2: Install R32.7.1 into NVME ssd

- Remove the m.2 ssd from the board and install it into a removable USB hard disk box
- Insert the hard disk box into ubuntu USB port
- Use `lsblk` to check the disk (In your system it might be `/dev/sdX`)

    ```bash
    seeed@ubuntu:~/$ lsblk
    NAME    MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
    sdb       8:16   0 119.2G  0 disk
    ├─sdb1    8:17   0    80G  0 part
    ├─sdb2    8:18   0    64M  0 part
    ├─sdb3    8:19   0    64M  0 part
    ├─sdb4    8:20   0   448K  0 part
    ├─sdb5    8:21   0   448K  0 part
    ├─sdb6    8:22   0    63M  0 part
    ├─sdb7    8:23   0   512K  0 part
    ├─sdb8    8:24   0   256K  0 part
    ├─sdb9    8:25   0   256K  0 part
    ├─sdb10   8:26   0   300M  0 part
    └─sdb11   8:27   0  38.8G  0 part
    ```
- Install R32.7.1 system

    ```bash
    seeed@ubuntu:~/$ tar xpf jetson-xavier-nx-J202DA-nvme-CAM50-preinstalled-20231012.tar.gz
    seeed@ubuntu:~/$ cd jetson-xavier-nx-J202DA-nvme-CAM50-preinstalled-20231012
    sudo -i
    root@ub:/home/seeed/jetson-xavier-nx-J202DA-nvme-CAM50-preinstalled-20231012# ./install.sh /dev/sdb
    ```

# 2. System not configured & e-CAM50 not installed

## Step 1: Roll back system to R32.7.1

```bash
seeed@ubuntu:~/$ tar xpf mfi_jetson-xavier-nx-J202DA-nvme-2023-10-11.tar.gz
seeed@ubuntu:~/$ cd mfi_jetson-xavier-nx-J202DA-nvme-2023-10-11/
seeed@ubuntu:~/mfi_jetson-xavier-nx-J202DA-nvme-2023-10-11$ sudo ./tools/kernel_flash/l4t_initrd_flash.sh --flash-only
```

## Step 2: Configure the system using a serial port or hdmi display

```bash
# setup /dev/ttyACM0, close Hardware flow control
nvidia@nvidia-desktop:~/$ sudo minicom -s /dev/ttyACM0
# configure the system
nvidia@nvidia-desktop:~/$ minicom -D /dev/ttyACM0
```

## Step 3: Install e-CAM50_CUNX_JETSON_L4T32.7.1_10-OCT-2023_R01

```bash
nvidia@nvidia-desktop:~/$ tar -zxf e-CAM50_CUNX_JETSON_L4T32.7.1_10-OCT-2023_R01.tar.gz
nvidia@nvidia-desktop:~/$ cd e-CAM50_CUNX_JETSON_L4T32.7.1_10-OCT-2023_R01
nvidia@nvidia-desktop:~/e-CAM50_CUNX_JETSON_L4T32.7.1_10-OCT-2023_R01$ sudo ./install_binaries.sh
```