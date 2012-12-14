#!/bin/bash

SWD="$( cd "$( dirname "$0" )" && pwd )"

download()
{
  local file_url=$1
  local file_dest=$2

  case $file_dest in
    */) if [ ! -d "$file_dest" ]; then
          mkdir -p "$file_dest"
        fi
        wget -nc -P "$file_dest" "$file_url";;
    *)  if [ ! -f "$file_dest" ]; then
          wget -nc -O "$file_dest" "$file_url"
        fi;;
  esac
}

extract()
{
  local file_src=$1
  local file_dest=$2

  if [ ! -f "$file_src" ]; then
    return 1
  fi

  if [ ! -d "$file_dest" ]; then
    mkdir -p "$file_dest"

    filetype=${file_src/*./}
    if [ "$filetype" == "tgz" ]; then
      tar -xzvf "$file_src" -C "$file_dest"
    elif [ "$filetype" == "zip" ]; then
      unzip "$file_src" -d "$file_dest"
    elif [ "$filetype" == "bz2" ]; then
      tar -xjvf "$file_src" -C "$file_dest"
    else
      echo "Extension \"$filetype\" is unknown, cannot extract $file_src"
    fi

  fi
}

download_and_extract()
{
  local file_url=$1
  local file_dest=$2
  local file_dir=$3

  case $file_dest in
    */) file_dest=$file_dest$(basename "$file_url")
  esac
  download $file_url $file_dest
  extract $file_dest $file_dir
}

DLDIR=$SWD/staging/downloads
BDIR=$SWD/staging/build
OUTDIR=$SWD/sdcard
mkdir -p $DLDIR
mkdir -p $BDIR

download_and_extract "http://images.barnesandnoble.com/PResources/download/Nook/source-code/nook2_1-2.tgz" "$DLDIR/" "$BDIR/nook_src"
download_and_extract "http://su.barnesandnoble.com/nook/nook2/1.2/aoW5Thnhd71GzQ7C3q6JFI2hXkaOufNIHjBYHo6i/nook_1_2_update.zip" "$DLDIR/" "$BDIR/nook_firmware"
download_and_extract "http://su.barnesandnoble.com/nook/nook2/1.1.2/byoyFa4tPqT3du0nSXTLrBeYy5CHbHS264o9Ujsh/nook_1_1_2_update.zip" "$DLDIR/" "$BDIR/nook_old_firmware"
download_and_extract "https://dl.dropbox.com/u/6408470/su-releases/su-2.3.6.1-ef-signed.zip" "$DLDIR/" "$BDIR/superuser"
download_and_extract "http://buildroot.uclibc.org/downloads/buildroot-2012.08.tar.bz2" "$DLDIR/" "$BDIR/buildroot"
download "https://github.com/CyanogenMod/android_frameworks_base/blob/jellybean/data/fonts/DroidSansFallback.ttf?raw=true" "$DLDIR/DroidSansFallback.ttf"
download "https://s3.amazonaws.com/github/downloads/yiselieren/ReLaunch/ReLaunch-1.3.8.apk" "$DLDIR/"
download "https://s3.amazonaws.com/github/downloads/doozan/NookTouchModManager/NookTouchModManager-0.3.0.apk" "$DLDIR/"
download "http://pool.apk.bazaarandroid.com/moonglo/com-amazon-venezia-201000-634745-98e61fd37521387e2e0b61be64a518b0.apk" "$DLDIR/"
download "https://smali.googlecode.com/files/baksmali-1.4.0.jar" "$DLDIR/"
download "https://smali.googlecode.com/files/smali-1.4.0.jar" "$DLDIR/"

if [ ! -d "$BDIR/nook_rescue" ]; then
  mkdir "$BDIR/nook_rescue"
  dd if="$BDIR/nook_firmware/ramdisk-recovery.img" of="$BDIR/nook_rescue/rescue.gz" bs=64 skip=1
  cd "$BDIR/nook_rescue/"
  zcat rescue.gz | cpio -id
  cd "$SWD"
fi

# copy custom buildroot settings to buildroot/custom
rsync -a --delete Buildroot/ "$BDIR/buildroot/buildroot-2012.08/custom"
cp Buildroot/buildroot-config "$BDIR/buildroot/buildroot-2012.08/.config"

# Create patched jars
if [ ! -d "$BDIR/patched-jars" ]; then
  mkdir -p "$BDIR/patched-jars"

  download "https://github.com/doozan/NookTouchPatches/raw/master/patches/1.2.0/android.policy.patch" "$BDIR/patched-jars/"
  download "https://github.com/doozan/NookTouchPatches/raw/master/patches/1.2.0/services.patch" "$BDIR/patched-jars/"
  dos2unix "$BDIR/patched-jars/android.policy.patch"
  dos2unix "$BDIR/patched-jars/services.patch"

  cp "$BDIR/nook_firmware/system/framework/android.policy.jar" "$BDIR/patched-jars/android.policy.orig.jar"
  cp "$BDIR/nook_firmware/system/framework/services.jar" "$BDIR/patched-jars/services.orig.jar"

  cd "$BDIR/patched-jars"

  java -jar "$DLDIR/baksmali-1.4.0.jar" -o android.policy android.policy.orig.jar
  java -jar "$DLDIR/baksmali-1.4.0.jar" -o services services.orig.jar

  patch -p1 < android.policy.patch
  patch -p1 < services.patch

  unzip android.policy.orig.jar -d android.policy-bin
  java -jar "$DLDIR/smali-1.4.0.jar" -o android.policy-bin/classes.dex android.policy
  cd android.policy-bin
  zip -9 ../android.policy.jar *
  cd ..

  unzip services.orig.jar -d services-bin
  java -jar "$DLDIR/smali-1.4.0.jar" -o services-bin/classes.dex services
  cd services-bin
  zip -9 ../services.jar *
  cd "$SWD"
fi

# Configure the nook sources as git repos so buildroot can checkout the source
if [ ! -d "$BDIR/nook_src/distro/u-boot/.git" ]; then
  cd "$BDIR/nook_src/distro/u-boot"
  git init
  git add .
  git commit -m "initial commit"
  cd "$SWD"
fi

if [ ! -d "$BDIR/nook_src/distro/kernel/.git" ]; then
  cd "$BDIR/nook_src/distro/kernel"
  git init
  git add .
  git commit -m "initial commit"
  cd "$SWD"
fi

# Run buildroot

cd "$BDIR/buildroot/buildroot-2012.08"
make
if [ "$?" -ne "0" ]; then exit; fi
mkimage -A arm -O linux -T ramdisk -C gzip -a 0 -e 0 -n "NookManager" -d output/images/rootfs.cpio.gz output/images/uRamdisk
cd "$SWD"

# build to565
#"$BDIR/buildroot/buildroot-2012.08/output/host/usr/bin/arm-none-linux-gnueabi-gcc" -O2 -Wall -Wno-unused-parameter -o "misc/to565" "misc/to565.c"

rm -rf "$OUTDIR"
mkdir -p "$OUTDIR/files/data/app"
mkdir -p "$OUTDIR/files/system/app"
mkdir -p "$OUTDIR/files/system/bin"
mkdir -p "$OUTDIR/files/system/fonts"
mkdir -p "$OUTDIR/files/system/framework"

# Create the contents of the sdcard in $OUTDIR
cp "$BDIR/buildroot/buildroot-2012.08/output/images/u-boot.bin" "$OUTDIR"
cp "$BDIR/buildroot/buildroot-2012.08/output/images/uImage" "$OUTDIR"
cp "$BDIR/buildroot/buildroot-2012.08/output/images/uRamdisk" "$OUTDIR"
mkimage -A arm -O linux -T script -C none -a 0 -e 0 -d "$SWD/misc/boot.script" "$OUTDIR/boot.scr"
cp "$BDIR/nook_firmware/MLO" "$OUTDIR"
cp "$BDIR/nook_firmware/wvf.bin" "$OUTDIR"
cp "$BDIR/nook_firmware/cfg.bin" "$OUTDIR"
cp "$BDIR/nook_firmware/flash_spl.bin" "$OUTDIR"
cp "$SWD/misc/booting.pgm" "$OUTDIR"
cp -r "$SWD/NookManager/"* "$OUTDIR/"

# Copy PackageInstaller from the old firmware (Needed for 1.2.0)
cp "$BDIR/nook_old_firmware/system/app/PackageInstaller.apk" "$OUTDIR/files/system/app"

cp "$BDIR/superuser/system/app/Superuser.apk" "$OUTDIR/files/data/app/com.noshufou.android.su.apk"
cp "$BDIR/superuser/system/bin/su" "$OUTDIR/files/system/bin/"
cp "$DLDIR/DroidSansFallback.ttf" "$OUTDIR/files/system/fonts/"
cp "$DLDIR/ReLaunch-1.3.8.apk" "$OUTDIR/files/data/app/com.harasoft.relaunch.apk"
cp "$DLDIR/NookTouchModManager-0.3.0.apk" "$OUTDIR/files/data/app/org.nookmods.ntmm.apk"
cp "$DLDIR/com-amazon-venezia-201000-634745-98e61fd37521387e2e0b61be64a518b0.apk" "$OUTDIR/files/data/app/com.android.venezia.apk"

cp "$BDIR/patched-jars/android.policy.jar" "$OUTDIR/files/system/framework/"
cp "$BDIR/patched-jars/services.jar" "$OUTDIR/files/system/framework/"

# Create image
dd if=/dev/zero of=NookManager.img bs=1MiB count=64
losetup /dev/loop0 NookManager.img
parted /dev/loop0 mklabel msdos
parted /dev/loop0 --align=cyl mkpart primary fat32 0 100%
parted /dev/loop0 set 1 boot on
losetup -o 16384 /dev/loop1 /dev/loop0
mkdosfs -F 32 -n "NookManager" /dev/loop1

if [ ! -d "$BDIR/tmpmount" ]; then
  mkdir "$BDIR/tmpmount"
fi
mount -t vfat /dev/loop1 "$BDIR/tmpmount"

rsync -a "$OUTDIR/" "$BDIR/tmpmount/"
sync
umount "$BDIR/tmpmount"

losetup -d /dev/loop1
sync
losetup -d /dev/loop0

echo "Build Complete.  You can now flash NookManager.img to a SD card."
