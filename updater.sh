#!/tmp/busybox sh
#
# Filsystem Conversion Script for Samsung Galaxy SL
# (c) 2011 by Teamhacksung
#

set -x
export PATH=/:/sbin:/system/xbin:/system/bin:/tmp:$PATH

# unmount everything
/tmp/busybox umount -l /system
/tmp/busybox umount -l /cache
/tmp/busybox umount -l /data
/tmp/busybox umount -l /dbdata
/tmp/busybox umount -l /efs

# create directories
/tmp/busybox mkdir -p /system
/tmp/busybox mkdir -p /cache
/tmp/busybox mkdir -p /data
/tmp/busybox mkdir -p /dbdata
/tmp/busybox mkdir -p /efs

# make sure internal sdcard is mounted
if ! /tmp/busybox grep -q /emmc /proc/mounts ; then
    /tmp/busybox mkdir -p /emmc
    /tmp/busybox umount -l /dev/block/mmcblk0p1
    if ! /tmp/busybox mount -t vfat /dev/block/mmcblk0p1 /emmc ; then
        /tmp/busybox echo "Cannot mount internal sdcard."
        exit 1
    fi
fi

# remove old log
rm -rf /emmc/cyanogenmod.log

# everything is logged into /emmc/cyanogenmod.log
exec >> /emmc/cyanogenmod.log 2>&1

# efs backup
if ! /tmp/busybox test -e /emmc/backup/efs/nv_data.bin ; then

    # make sure efs is mounted
    if ! /tmp/busybox grep -q /efs /proc/mounts ; then
        /tmp/busybox mkdir -p /efs
        /tmp/busybox umount -l /dev/block/stl3
        if ! /tmp/busybox mount -t rfs /dev/block/stl3 /efs ; then
            /tmp/busybox echo "Cannot mount efs."
            exit 2
        fi
fi

    # create a backup of efs
    if /tmp/busybox test -e /emmc/backup/efs ; then
        /tmp/busybox mv /emmc/backup/efs /emmc/backup/efs-$$
    fi
    /tmp/busybox rm -rf /emmc/backup/efs
    
    /tmp/busybox mkdir -p /emmc/backup/efs
    /tmp/busybox cp -R /efs/ /emmc/backup
fi

#
# filesystem conversion
#

# format system if not ext4
if ! /tmp/busybox mount -t ext4 /dev/block/stl9 /system ; then
    /tmp/busybox umount /system
    /tmp/make_ext4fs -b 4096 -g 32768 -i 8192 -I 256 -a /data /dev/block/stl9
fi

# format dbdata if not ext4
if ! /tmp/busybox mount -t ext4 /dev/block/stl10 /dbdata ; then
    /tmp/busybox umount /dbdata
    /tmp/make_ext4fs -b 4096 -g 32768 -i 8192 -I 256 -a /data /dev/block/stl10
fi

# format cache if not ext4
if ! /tmp/busybox mount -t ext4 /dev/block/stl11 /cache ; then
    /tmp/busybox umount /cache
    /tmp/make_ext4fs -b 4096 -g 32768 -i 8192 -I 256 -a /data /dev/block/stl11
fi

# format data if not ext4
if ! /tmp/busybox mount -t ext4 /dev/block/mmcblk0p3 /data ; then
    /tmp/busybox umount /data
    /tmp/make_ext4fs -b 4096 -g 32768 -i 8192 -I 256 -a /data /dev/block/mmcblk0p3
fi

# unmount everything
/tmp/busybox umount -l /system
/tmp/busybox umount -l /cache
/tmp/busybox umount -l /data
/tmp/busybox umount -l /dbdata
/tmp/busybox umount -l /efs

exit 0