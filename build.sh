#!/bin/bash

#
# Quanta Kernel build script
#
# How to use:
# Compiling wihtout any arguments will compile the AOSP version
# Compiling with cm or CM for an argument will compile the CM version
#
#

export CROSS_COMPILE="$HOME/uber-arm-eabi-5.1/bin/arm-eabi-"
KERNEL_DIRECTORY="$HOME/Quanta-Mako"
ANYKERNEL_DIRECTORY="$HOME/anykernel_msm"
JOBS=`grep -c "processor" /proc/cpuinfo`
# Verify if the CM patches has already been applied. We don't want to apply them again if the compiling is stopped
CM_CHECK=`grep -c "case MDP_YCBYCR_H2V1:" drivers/video/msm/mdp4_overlay.c`
VERSION=4


if [[ "$1" =~ "cm" || "$1" =~ "CM" ]] ; then
kernelzip="Quanta-V$VERSION-CM.zip"

if [ $CM_CHECK -eq 0 ] ; then
git am CM/*
fi

else
kernelzip="Quanta-V$VERSION.zip"
fi


cd $ANYKERNEL_DIRECTORY
git checkout mako-5.1

cd $KERNEL_DIRECTORY

mkdir -p ./zip

if [ -e zip/*.zip ] ; then
rm -rf zip/*
fi

# Strangely, the kernel after compiling, auto-increments the version by 1. Let's revert that by decreasing the version value also by 1.
let "VERSION -= 1"

echo $VERSION > .version
make quanta_defconfig
make -j$JOBS

if [ -f arch/arm/boot/zImage ] ; then
cd $ANYKERNEL_DIRECTORY
cp -r * $KERNEL_DIRECTORY/zip/
cd $KERNEL_DIRECTORY
cp arch/arm/boot/zImage zip/tmp/anykernel

if [[ "$1" =~ "cm" || "$1" =~ "CM" ]] ; then
git reset --hard HEAD~2
fi
 
cd zip/
zip -r $kernelzip *
echo "The kernel is situated at zip/$kernelzip"
fi
