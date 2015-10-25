#!/bin/bash
#
#
# Quanta Kernel build script
#
# How to use:
# Compiling wihtout any arguments will compile the AOSP version
# Compiling with cm or CM for an argument will compile the CM version
#
#

export CROSS_COMPILE="$HOME/uber-arm-eabi-5.2/bin/arm-eabi-"
KERNEL_DIRECTORY="$HOME/Quanta-Mako"
ANYKERNEL_DIRECTORY="$HOME/anykernel_msm"
JOBS=`grep -c "processor" /proc/cpuinfo`
# Verify if the CM patches has already been applied. We don't want to apply them again if the compiling is stopped
CM_CHECK=`grep -c "case MDP_YCBYCR_H2V1:" drivers/video/msm/mdp4_overlay.c`
DEVICE="Mako"
VERSION=7


# Function responsible for download Anykernel if it's not found by the ANYKERNEL_DIRECTORY variable.
function download_anykernel() {
echo "Anykernel hasn't been found in $ANYKERNEL_DIRECTORY."
echo "Downloading it..."
git clone https://github.com/zaclimon/anykernel_msm -b mako-6.0 $ANYKERNEL_DIRECTORY
} 

# Download Anykernel if not found.
if [ ! -d $ANYKERNEL_DIRECTORY ] ; then
download_anykernel
fi

# Set the packaging information here. Specify if CM or AOSP.
if [[ "$1" =~ "cm" || "$1" =~ "CM" ]] ; then
kernelzip="Quanta-V$VERSION-CM-$DEVICE.zip"

# Apply the CM patches if the variant specified is CM.
if [ $CM_CHECK -eq 0 ] ; then
git am CM/*
fi

else
kernelzip="Quanta-V$VERSION-$DEVICE.zip"
fi

# Ensure that we're on the correct Anykernel branch
cd $ANYKERNEL_DIRECTORY
git checkout mako-6.0

cd $KERNEL_DIRECTORY

# Create a /zip directory if not present
mkdir -p ./zip

# Clean the /zip directory if there have been a zip file before (Mostly a version of Quanta compiled.)
if [ -e zip/*.zip ] ; then
rm -rf zip/*
fi

# Strangely, the kernel after compiling, auto-increments the version by 1. Let's revert that by decreasing the version value also by 1.
let "VERSION -= 1"

echo $VERSION > .version
make quanta_defconfig
make -j$JOBS

# Copy the contents of the Anykernel folder if we confirm that a zImage is present.
if [ -f arch/arm/boot/zImage ] ; then
cd $ANYKERNEL_DIRECTORY
cp -r * $KERNEL_DIRECTORY/zip/
cd $KERNEL_DIRECTORY
cp arch/arm/boot/zImage zip/tmp/anykernel

# Remove the previously applied CM patches if we compiled with them before.
if [[ "$1" =~ "cm" || "$1" =~ "CM" ]] ; then
git reset --hard HEAD~2
fi
 
cd zip/
zip -r $kernelzip *
echo "The kernel is situated at zip/$kernelzip"
fi
