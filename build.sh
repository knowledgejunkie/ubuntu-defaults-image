#! /bin/sh
# Wrapper for NHoS using customised ubuntu-defaults-image

# Usage:
# Run with sudo -E

# Requires ENV VAR for arch & flavor (Gnome / Cinnamon / Mate)
# $ BUILDARCH=amd64 BUILDFLAVOUR=gnome sudo -E ./build.sh

# Optional ENV VAR for logging
# $ BUILDLOG=quiet BUILDARCH=amd64 BUILDFLAVOUR=gnome sudo -E ./build.sh

# Set variables for script
BUILD_TIDY=false

if [ -z "$BUILDFLAVOUR" ]; then
  BUILDFLAVOUR=gnome
fi

# Set variables for live-build
export BUILD_ISO_ARCH=$BUILDARCH
export BUILD_ISO_WORKDIR=$BUILDARCH
export BUILD_ISO_FLAVOUR=$BUILDFLAVOUR
export BUILD_ISO_DATE=$(date +%Y%m%d)
export BUILD_ISO_FILE="NHoS-$BUILD_ISO_FLAVOUR-$BUILD_ISO_ARCH-$BUILD_ISO_DATE"
export LB_ISO_TITLE=NHoS
export LB_ISO_VOLUME="NHoS $BUILD_ISO_FLAVOUR $BUILD_ISO_ARCH $BUILD_ISO_DATE"

# Set logging output
if [ "$BUILDLOG" = "quiet" ]
  then
    export BUILD_LOGGING="quiet"
    export BUILD_LOGSTATE="../$BUILD_ISO_FILE.log"
    export BUILD_LOGOPTS=">> ../$BUILD_ISO_FILE.log"
    rm -f ../$BUILD_ISO_FILE
  else
    export BUILD_LOGGING="normal"
    export BUILD_LOGSTATE="console"
    export BUILD_LOGOPTS=
fi

# INFO: to console
echo "INFO: Build workdir is ${BUILD_ISO_WORKDIR}"
echo "INFO: Build logging set to ${BUILD_LOGGING}"
echo "INFO: Build log output to ${BUILD_LOGSTATE}"
echo "INFO: Build architecture is ${BUILD_ISO_ARCH}"
echo "INFO: Build flavor is ${BUILD_ISO_FLAVOUR}"
echo "INFO: Build ISO filename is ${BUILD_ISO_FILE}"
echo "INFO: live-build ISO title is ${LB_ISO_TITLE}"
echo "INFO: live-build ISO volume is ${LB_ISO_VOLUME}"

# Install dependencies
# These dependencies are installed in our Docker image
echo "INFO: Checking / installing dependencies"
apt-get install -qq -y curl git live-build cdebootstrap ubuntu-defaults-builder syslinux-utils genisoimage memtest86+ syslinux syslinux-themes-ubuntu-xenial gfxboot-theme-ubuntu livecd-rootfs

# Patch lb_binary_disk to support $LB_ISO_VOLUME
echo "INFO: Checking lb_binary_disk"
grep LB_ISO_TITLE /usr/lib/live/build/lb_binary_disk > /dev/null
if [ $? -eq 0 ]; then
  echo "INFO: Checked lb_binary_disk"
else
  echo "INFO: Patching lb_binary_disk"
  cp /usr/lib/live/build/lb_binary_disk /usr/lib/live/build/lb_binary_disk.orig
  sed -i 's/TITLE="Ubuntu"/TITLE="${LB_ISO_TITLE}"/' /usr/lib/live/build/lb_binary_disk
fi
echo "INFO: Verified lb_binary_disk"

# Setup build
echo "INFO: Create workdir for build"

# Make workdir for arch
if [ ! -d "$BUILD_ISO_WORKDIR" ]; then
  mkdir $BUILD_ISO_WORKDIR
fi
cd $BUILD_ISO_WORKDIR

# Run build
echo "INFO: Build started"

# For build - ubuntu-gnome
if [ "$BUILD_ISO_FLAVOUR" = "gnome" ]; then
  echo "INFO: Building NHoS - gnome"
  # Start build with options
  BUILD_ISO_CMD="../ubuntu-defaults-image --ppa nhsbuntu/ppa --ppa libreoffice/ppa --package nhos-default-settings --arch $BUILD_ISO_ARCH --release xenial --flavor ubuntu-gnome ${BUILD_LOGOPTS}"
  echo "EXEC: $BUILD_ISO_CMD"
  eval $BUILD_ISO_CMD
fi

# For build - ubuntu-gnome-nightly
if [ "$BUILD_ISO_FLAVOUR" = "gnome-nightly" ]; then
  echo "INFO: Building NHoS - gnome-nightly"
  # Start build with options
  BUILD_ISO_CMD="../ubuntu-defaults-image --ppa nhsbuntu/ppa --ppa libreoffice/ppa --package nhos-default-settings --arch $BUILD_ISO_ARCH --release xenial --flavor ubuntu-gnome --repo nhsbuntu/nhos-default-settings ${BUILD_LOGOPTS}"
  echo "EXEC: $BUILD_ISO_CMD"
  eval $BUILD_ISO_CMD
fi

# For build - ubuntu-gnome test
if [ "$BUILD_ISO_FLAVOUR" = "gnome-test" ]; then
  echo "INFO: Building NHoS - Gnome - Test"
  # Start build with options
  BUILD_ISO_CMD="../ubuntu-defaults-image --package nhos-default-settings --arch $BUILD_ISO_ARCH --release xenial --flavor ubuntu-gnome --repo nhsbuntu/nhos-default-settings-test ${BUILD_LOGOPTS}"
  echo "EXEC: $BUILD_ISO_CMD"
    eval $BUILD_ISO_CMD
fi

# For build - ubuntu-gnome & cinnamon dev
if [ "$BUILD_ISO_FLAVOUR" = "cinnamon-dev" ]; then
  echo "INFO: Building NHoS - Cinnamon - Dev"
  # Start build with options
  BUILD_ISO_CMD="../ubuntu-defaults-image --ppa embrosyn/cinnamon --package nhos-default-settings --xpackage cinnamon --arch $BUILD_ISO_ARCH --release xenial --flavor ubuntu-gnome --repo nhsbuntu/nhos-default-settings-dev ${BUILD_LOGOPTS}"
  echo "EXEC: $BUILD_ISO_CMD"
  eval $BUILD_ISO_CMD
fi

# For build - ubuntu-mate dev
if [ "$BUILD_ISO_FLAVOUR" = "mate-dev" ]; then
  echo "INFO: Building NHSbuntu - Mate - Development"
  # Start build with options
  BUILD_ISO_CMD="../ubuntu-defaults-image --ppa ubuntu-x-swat/updates --package nhsbuntu-default-settings --arch $BUILD_ISO_ARCH --release xenial --flavor ubuntu-mate --repo nhsbuntu/nhos-default-settings-dev ${BUILD_LOGOPTS}"
  echo "EXEC: $BUILD_ISO_CMD"
  eval $BUILD_ISO_CMD
fi

echo "INFO: Build ended"

# Check for ISOs
BUILD_OUTISO_BINARY=$(ls -1|grep binary|grep iso)
BUILD_OUTISO_LIVECD=$(ls -1|grep livecd|grep iso)

if [ -f "$BUILD_OUTISO_BINARY" ]
  then
    echo "INFO: Found $BUILD_OUTISO_BINARY"
    echo "INFO: Renaming binary ISO file"
    mv $BUILD_OUTISO_BINARY $BUILD_ISO_FILE-binary.iso
    echo "INFO: Generating checksums"
    md5sum $BUILD_ISO_FILE-binary.iso > $BUILD_ISO_FILE-binary.iso.md5sum.txt
    sha1sum $BUILD_ISO_FILE-binary.iso > $BUILD_ISO_FILE-binary.iso.sha1sum.txt
    sha256sum $BUILD_ISO_FILE-binary.iso > $BUILD_ISO_FILE-binary.iso.sha256sum.txt
    BUILD_ISO_FILE_MD5=$(md5sum $BUILD_ISO_FILE-binary.iso|cut -d ' ' -f1)
    BUILD_ISO_FILE_SHA1=$(sha1sum $BUILD_ISO_FILE-binary.iso|cut -d ' ' -f1)
    BUILD_ISO_FILE_SHA256=$(sha256sum $BUILD_ISO_FILE-binary.iso|cut -d ' ' -f1)
    echo "$BUILD_ISO_FILE-binary.iso,$BUILD_ISO_ARCH,$BUILD_ISO_FLAVOUR,$BUILD_ISO_DATE,$BUILD_ISO_FILE_MD5,$BUILD_ISO_FILE_SHA1,$BUILD_ISO_FILE_SHA256" > $BUILD_ISO_FILE-binary.iso.checksum.csv
    mv $BUILD_ISO_FILE-binary.iso $BUILD_ISO_FILE-binary.iso.checksum.csv $BUILD_ISO_FILE-binary.iso.md5sum.txt $BUILD_ISO_FILE-binary.iso.sha1sum.txt $BUILD_ISO_FILE-binary.iso.sha256sum.txt ../
    BUILD_OUTISO_STATE=true
  else
    echo "INFO: binary ISO file not found"
    BUILD_OUTISO_STATE=false
fi

if [ -f "$BUILD_OUTISO_LIVECD" ]
  then
    echo "INFO: Found $BUILD_OUTISO_LIVECD"
    echo "INFO: Renaming livecd ISO file"
    mv $BUILD_OUTISO_LIVECD $BUILD_ISO_FILE-livecd.iso
    echo "INFO: Generating checksums"
    md5sum $BUILD_ISO_FILE-livecd.iso > $BUILD_ISO_FILE-livecd.iso.md5sum.txt
    sha1sum $BUILD_ISO_FILE-livecd.iso > $BUILD_ISO_FILE-livecd.iso.sha1sum.txt
    sha256sum $BUILD_ISO_FILE-livecd.iso > $BUILD_ISO_FILE-livecd.iso.sha256sum.txt
    BUILD_ISO_FILE_MD5=$(md5sum $BUILD_ISO_FILE-livecd.iso|cut -d ' ' -f1)
    BUILD_ISO_FILE_SHA1=$(sha1sum $BUILD_ISO_FILE-livecd.iso|cut -d ' ' -f1)
    BUILD_ISO_FILE_SHA256=$(sha256sum $BUILD_ISO_FILE-livecd.iso|cut -d ' ' -f1)
    echo "$BUILD_ISO_FILE-livecd.iso,$BUILD_ISO_ARCH,$BUILD_ISO_FLAVOUR,$BUILD_ISO_DATE,$BUILD_ISO_FILE_MD5,$BUILD_ISO_FILE_SHA1,$BUILD_ISO_FILE_SHA256" > $BUILD_ISO_FILE-livecd.iso.checksum.csv
    mv $BUILD_ISO_FILE-livecd.iso $BUILD_ISO_FILE-livecd.iso.checksum.csv $BUILD_ISO_FILE-livecd.iso.md5sum.txt $BUILD_ISO_FILE-livecd.iso.sha1sum.txt $BUILD_ISO_FILE-livecd.iso.sha256sum.txt ../
    BUILD_OUTISO_STATE=true
  else
    echo "INFO: livecd ISO file not found"
    BUILD_OUTISO_STATE=false
fi

if [ "${BUILD_OUTISO_STATE}" = true ]
  then
    echo "INFO: Built ISOs Successfully"
  else
    echo "INFO: Failed to build ISOs"
    exit 1
fi

if [ "$BUILD_TIDY" = "true" ]
  then
    echo "INFO: Tidying up"
    cd ../
    rm -rf $BUILD_ISO_WORKDIR
  else
    cd ../
fi

echo "INFO: Finished"
exit 0
