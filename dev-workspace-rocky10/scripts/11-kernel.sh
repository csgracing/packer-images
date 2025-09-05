#!/bin/sh


set -e

KERNEL_VERSION=6.12.42
KERNEL_EXTRAVERSION=csgr
KERNEL_WORKING_DIR=/opt/kernel/$KERNEL_VERSION
KERNEL_SOURCE_DIR=$KERNEL_WORKING_DIR/src


# install additional dependencies
dnf -y install ncurses-devel openssl-devel elfutils-libelf-devel python3 dwarves bc

mkdir -p $KERNEL_SOURCE_DIR

cd $KERNEL_WORKING_DIR

curl -L -o linux-$KERNEL_VERSION.tar.xz https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$KERNEL_VERSION.tar.xz

# extract into working dir (without parent folder)
tar xJf linux-$KERNEL_VERSION.tar.xz -C $KERNEL_SOURCE_DIR --strip-components 1

# kernel src now present in /opt/kernel/$KERNEL_VERSION/src


cd $KERNEL_SOURCE_DIR

# kernel config, see also: https://unix.stackexchange.com/a/325593

# generate default config
make defconfig

# get running config
# cat /lib/modules/$(uname -r)/build/.config > .config


# append our changes
echo "
CONFIG_CAN=m
CONFIG_CAN_RAW=m
CONFIG_CAN_BCM=m
CONFIG_CAN_GW=m
CONFIG_CAN_J1939=m
CONFIG_CAN_ISOTP=m
CONFIG_DMI_SCAN_MACHINE_NON_EFI_FALLBACK=y
# CONFIG_SCSI_SCAN_ASYNC is not set
CONFIG_CAN_DEV=m
CONFIG_CAN_VCAN=m
CONFIG_CAN_VXCAN=m
CONFIG_CAN_NETLINK=y
CONFIG_CAN_CALC_BITTIMING=y
CONFIG_CAN_RX_OFFLOAD=y
CONFIG_CAN_CAN327=m
CONFIG_CAN_KVASER_PCIEFD=m
CONFIG_CAN_SLCAN=m
CONFIG_CAN_C_CAN=m
# CONFIG_CAN_C_CAN_PLATFORM is not set
# CONFIG_CAN_C_CAN_PCI is not set
CONFIG_CAN_CC770=m
# CONFIG_CAN_CC770_ISA is not set
# CONFIG_CAN_CC770_PLATFORM is not set
CONFIG_CAN_CTUCANFD=m
CONFIG_CAN_CTUCANFD_PCI=m
CONFIG_CAN_ESD_402_PCI=m
CONFIG_CAN_IFI_CANFD=m
CONFIG_CAN_M_CAN=m
# CONFIG_CAN_M_CAN_PCI is not set
# CONFIG_CAN_M_CAN_PLATFORM is not set
CONFIG_CAN_PEAK_PCIEFD=m
CONFIG_CAN_SJA1000=m
# CONFIG_CAN_EMS_PCI is not set
# CONFIG_CAN_EMS_PCMCIA is not set
# CONFIG_CAN_F81601 is not set
# CONFIG_CAN_KVASER_PCI is not set
# CONFIG_CAN_PEAK_PCI is not set
# CONFIG_CAN_PEAK_PCMCIA is not set
# CONFIG_CAN_PLX_PCI is not set
# CONFIG_CAN_SJA1000_ISA is not set
# CONFIG_CAN_SJA1000_PLATFORM is not set
CONFIG_CAN_SOFTING=m
CONFIG_CAN_SOFTING_CS=m
# CAN USB interfaces
CONFIG_CAN_8DEV_USB=m
CONFIG_CAN_EMS_USB=m
CONFIG_CAN_ESD_USB=m
CONFIG_CAN_ETAS_ES58X=m
CONFIG_CAN_F81604=m
CONFIG_CAN_GS_USB=m
CONFIG_CAN_KVASER_USB=m
CONFIG_CAN_MCBA_USB=m
CONFIG_CAN_PEAK_USB=m
CONFIG_CAN_UCAN=m
# end of CAN USB interfaces
# CONFIG_CAN_DEBUG_DEVICES is not set
# CONFIG_PHY_CAN_TRANSCEIVER is not set
# CONFIG_TEST_SCANF is not set
CONFIG_XFS_FS=m
" >> .config

# fix up any inconsistencies (note that we should still validate the output...)
make olddefconfig


# set extraversion using var
sed  -i 's/^EXTRAVERSION.*/EXTRAVERSION = -'$KERNEL_EXTRAVERSION'/'  Makefile

# build kernel (use all cores)
make -j $(nproc)

# kernel now in ./arch/x86/boot/bzImage

# copy kernel and system map
cp  ./arch/x86/boot/bzImage /boot/vmlinuz-$KERNEL_VERSION-$KERNEL_EXTRAVERSION
cp  ./System.map /boot/System-map-$KERNEL_VERSION-$KERNEL_EXTRAVERSION

# install kernel modules (stripped)
INSTALL_MOD_STRIP=1 make modules_install

# "install" the kernel (register it)
kernel-install add $KERNEL_VERSION-$KERNEL_EXTRAVERSION /boot/vmlinuz-$KERNEL_VERSION-$KERNEL_EXTRAVERSION

