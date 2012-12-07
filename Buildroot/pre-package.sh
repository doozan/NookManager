#!/bin/sh

TARGET=$1
SDIR="$TARGET/../../../../../.."
BDIR=$SDIR/staging/build
DLDIR=$SDIR/staging/downloads

rm -rf "$TARGET/system"
mkdir -p "$TARGET/system/bin"
mkdir -p "$TARGET/system/lib"

cp "$SDIR/misc/to565" "$TARGET/bin/"
cp -r "$TARGET/../../custom/fs-overlay/"* "$TARGET/"

cp "$BDIR/nook_rescue/init"         "$TARGET/"
cp "$BDIR/nook_rescue/initlogo.rle" "$TARGET/"

cp -r "$BDIR/nook_rescue/etc/dsp"  "$TARGET/etc/"

cp "$BDIR/nook_rescue/sbin/adbd"           "$TARGET/sbin/"
cp "$BDIR/nook_rescue/sbin/omap-edpd.elf"  "$TARGET/sbin/"
cp "$BDIR/nook_rescue/sbin/bridged"        "$TARGET/sbin/"
cp "$BDIR/nook_rescue/sbin/cexec.out"      "$TARGET/sbin/"

cp "$BDIR/nook_firmware/system/bin/toolbox" "$TARGET/sbin/"
ln -fs /sbin/toolbox "$TARGET/sbin/getevent"
ln -fs /sbin/toolbox "$TARGET/sbin/getprop"
ln -fs /sbin/toolbox "$TARGET/sbin/hd"
ln -fs /sbin/toolbox "$TARGET/sbin/newfs_msdos"
ln -fs /sbin/toolbox "$TARGET/sbin/notify"
ln -fs /sbin/toolbox "$TARGET/sbin/printenv"
ln -fs /sbin/toolbox "$TARGET/sbin/reboot"
ln -fs /sbin/toolbox "$TARGET/sbin/route"
ln -fs /sbin/toolbox "$TARGET/sbin/sendevent"
ln -fs /sbin/toolbox "$TARGET/sbin/setconsole"
ln -fs /sbin/toolbox "$TARGET/sbin/setprop"
ln -fs /sbin/toolbox "$TARGET/sbin/smd"
ln -fs /sbin/toolbox "$TARGET/sbin/start"
ln -fs /sbin/toolbox "$TARGET/sbin/stop"
ln -fs /sbin/toolbox "$TARGET/sbin/vmstat"
ln -fs /sbin/toolbox "$TARGET/sbin/watchprops"

# Linker + libraries required for toolbox binary
cp "$BDIR/nook_firmware/system/bin/linker" "$TARGET/system/bin"
chmod +x "$TARGET/system/bin/linker"

cp "$BDIR/nook_firmware/system/lib/libcutils.so" "$TARGET/system/lib"
cp "$BDIR/nook_firmware/system/lib/liblog.so" "$TARGET/system/lib"
cp "$BDIR/nook_firmware/system/lib/libm.so" "$TARGET/system/lib"
cp "$BDIR/nook_firmware/system/lib/libstdc++.so" "$TARGET/system/lib"
cp "$BDIR/nook_firmware/system/lib/libc.so" "$TARGET/system/lib"

# needed for wpa_supplicant
cp "$BDIR/nook_firmware/system/lib/libcrypto.so" "$TARGET/system/lib"
cp "$BDIR/nook_firmware/system/lib/libssl.so" "$TARGET/system/lib"

cp -r "$BDIR/nook_firmware/system/etc/wifi" "$TARGET/etc/"
cp "$BDIR/nook_firmware/system/bin/tiwlan_loader" "$TARGET/sbin/"
cp "$BDIR/nook_firmware/system/bin/wpa_supplicant" "$TARGET/sbin/"
cp "$BDIR/nook_firmware/system/bin/dhcpcd" "$TARGET/sbin/"
cp "$BDIR/nook_firmware/system/bin/logcat" "$TARGET/sbin/"

mkdir "$TARGET/system/etc"
cp -r "$BDIR/nook_firmware/system/etc/dhcpcd" "$TARGET/system/etc/"
chmod +x "$TARGET/system/etc/dhcpcd/dhcpcd-run-hooks"

chmod +x "$TARGET/sbin/"*

# /system/bin/sh required for adb shell
ln -s /bin/busybox "$TARGET/system/bin/sh"

