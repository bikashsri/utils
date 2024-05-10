#  Source:
# https://gist.github.com/wuhanstudio/e9b37b07312a52ceb5973aacf580c453

# Install QEMU-6.1.0
wget https://download.qemu.org/qemu-6.1.0.tar.xz
tar xvJf qemu-6.1.0.tar.xz
cd qemu-6.1.0
./configure
make
sudo make install

# Download Armbian (Ubuntu Focal 20.04) for OrangePi PC
wget https://mirrors.netix.net/armbian/dl/orangepipc/archive/Armbian_21.08.1_Orangepipc_focal_current_5.10.60.img.xz
sudo apt-get install xz-utils
unxz Armbian_21.08.1_Orangepipc_focal_current_5.10.60.img.xz

# Create SD Image for QEMU
fallocate -l 16G armbian.img
dd conv=notrunc if=Armbian_21.08.1_Orangepipc_focal_current_5.10.60.img of=armbian.img bs=2G
fdisk -lu armbian.img
##########################################################################
# Offset Calculation
##########################################################################
#
#  $ usr/sbin/fdisk -lu armbian.img
#  Disk armbian.img: 16 GiB, 17179869184 bytes, 33554432 sectors
#  Units: sectors of 1 * 512 = 512 bytes
#  Sector size (logical/physical): 512 bytes / 512 bytes
#  I/O size (minimum/optimal): 512 bytes / 512 bytes
#  Disklabel type: dos
#  Disk identifier: 0xf2d1a856
#
#  Device       Boot Start      End  Sectors  Size Id Type
#  armbian.img1      32768 14278655 14245888  6.8G 83 Linux
#

#
# Offset = 512 * 32768
#
##########################################################################

# sudo mount -o loop,offset=Boot*512 armbian.img /mnt/
sudo mount -o loop,offset=4194304 armbian.img /mnt/

# Copy vmlinuz dtb initrd
sudo cp /mnt/boot/vmlinuz-5.10.60-sunxi ./
sudo cp /mnt/boot/dtb-5.10.60-sunxi/sun8i-h3-orangepi-pc.dtb ./
sudo cp /mnt/boot/initrd.img-5.10.60-sunxi ./

# Resize the img partition size
sudo apt install gparted
sudo umount /mnt
sudo modprobe loop
LOOP_DEVICE=`sudo losetup -f`
sudo losetup $LOOP_DEVICE armbian.img
sudo parted $LOOP_DEVICE

# print
# resizepart 1 16GB

# Fix potential errors in the filesystem
# sudo partprobe $LOOP_DEVICE
# LOOP_DEVICE_P1="${LOOP_DEVICE}p1"
# sudo e2fsck -f $LOOP_DEVICE_P1
# sudo resize2fs $LOOP_DEVICE_P1 16G

sudo losetup -d $LOOP_DEVICE

# Start QEMU
qemu-system-arm -M orangepi-pc -m 1G -smp 4\
    -kernel vmlinuz-5.10.60-sunxi \
    -dtb sun8i-h3-orangepi-pc.dtb \
    -initrd initrd.img-5.10.60-sunxi \
    -sd armbian.img \
    -append 'console=ttyS0,115200 root=/dev/mmcblk0p1' \
    -nic user,hostfwd=tcp::2022-:22,model=allwinner-sun8i-emac \
    -no-reboot -serial stdio -nographic -monitor none

# Resize filesystem in Orange Pi
sudo resize2fs /dev/mmcblk0p1
