#!/bin/sh
export KERNELDIR=`readlink -f .`
export RAMFS_SOURCE="/home/francesco/Googy-Max4-Kernel/Ramdisks/ramfs_cm12"
export PARENT_DIR=`readlink -f ..`
export USE_SEC_FIPS_MODE=true
export CROSS_COMPILE=/home/francesco/arm-cortex_a15-linux-gnueabihf-linaro_4.9.4-2015.06/bin/arm-cortex_a15-linux-gnueabihf-

# if [ "v2" != "" ];then
#  export KERNELDIR=`readlink -f v2`
# fi

RAMFS_TMP="/home/francesco/Googy-Max4-Kernel/tmp_cm/ramfs"

VER="\"-GoogyMax4_CM-v2\""
cp -f /home/francesco/Googy-Max4-Kernel/Kernel_cm/arch/arm/configs/0googymax4_CM_defconfig /home/francesco/Googy-Max4-Kernel/0googymax4_CM_defconfig
sed "s#^CONFIG_LOCALVERSION=.*#CONFIG_LOCALVERSION=$VER#" /home/francesco/Googy-Max4-Kernel/0googymax4_CM_defconfig > /home/francesco/Googy-Max4-Kernel/Kernel_cm/arch/arm/configs/0googymax4_CM_defconfig

# 
make 0googymax4_CM_defconfig VARIANT_DEFCONFIG=msm8974pro_sec_klte_eur_defconfig SELINUX_DEFCONFIG=selinux_defconfig || exit 1

. $KERNELDIR/.config

export KCONFIG_NOTIMESTAMP=true
export ARCH=arm

cd $KERNELDIR/
make -j3 || exit 1

#remove previous ramfs files
rm -rf $RAMFS_TMP
rm -rf $RAMFS_TMP.cpio
rm -rf $RAMFS_TMP.cpio.gz
rm -rf $RAMFS_TMP/*
#copy ramfs files to tmp directory
cp -ax $RAMFS_SOURCE $RAMFS_TMP
#clear git repositories in ramfs
find $RAMFS_TMP -name .git -exec rm -rf {} \;
#remove orig backup files
# find $RAMFS_TMP -name .orig -exec rm -rf {} \;
#remove empty directory placeholders
find $RAMFS_TMP -name EMPTY_DIRECTORY -exec rm -rf {} \;
#remove mercurial repository
rm -rf $RAMFS_TMP/.hg
#copy modules into ramfs
mkdir -p /home/francesco/Googy-Max4-Kernel/G900F_GoogyMax4_CM.CWM/system/lib/modules
rm -rf /home/francesco/Googy-Max4-Kernel/G900F_GoogyMax4_CM.CWM/system/lib/modules/*
find -name '*.ko' -exec cp -av {} /home/francesco/Googy-Max4-Kernel/G900F_GoogyMax4_CM.CWM/system/lib/modules/ \;
${CROSS_COMPILE}strip --strip-unneeded /home/francesco/Googy-Max4-Kernel/G900F_GoogyMax4_CM.CWM/system/lib/modules/*

cd $RAMFS_TMP
find | fakeroot cpio -H newc -o > $RAMFS_TMP.cpio 2>/dev/null
ls -lh $RAMFS_TMP.cpio
gzip -9 $RAMFS_TMP.cpio
cd -

tools/dtbTool -o arch/arm/boot/dt.img -s 2048 -p scripts/dtc/ arch/arm/boot/
chmod a+r arch/arm/boot/dt.img
tools/mkbootimg --cmdline 'console=null androidboot.hardware=qcom user_debug=23 msm_rtb.filter=0x37 ehci-hcd.park=3 androidboot.selinux=permissive' --kernel $KERNELDIR/arch/arm/boot/zImage --ramdisk $RAMFS_TMP.cpio.gz --base 0x00000000 --pagesize 2048 --ramdisk_offset 0x02000000 --tags_offset 0x01E00000 --dt arch/arm/boot/dt.img --output $KERNELDIR/boot.img 		

cd /home/francesco/Googy-Max4-Kernel
mv -f -v /home/francesco/Googy-Max4-Kernel/Kernel_cm/boot.img /home/francesco/Googy-Max4-Kernel/G900F_GoogyMax4_CM.CWM/boot.img
cd /home/francesco/Googy-Max4-Kernel/G900F_GoogyMax4_CM.CWM
zip -r ../GoogyMax4_CM-Kernel_v2_CWM.zip .

adb push /home/francesco/Googy-Max4-Kernel/GoogyMax4_CM-Kernel_v2_CWM.zip /storage/sdcard1/GoogyMax4_CM-Kernel_${1}_CWM.zip

# adb push /home/francesco/Googy-Max4-Kernel/GoogyMax4_CM-Kernel_v2_CWM.zip /storage/sdcard1/update-gmax4.zip
# 
# adb shell su -c "echo 'boot-recovery ' > /cache/recovery/command"
# adb shell su -c "echo '--update_package=/storage/sdcard0/update-gmax4.zip' >> /cache/recovery/command"
# adb shell su -c "reboot recovery"
