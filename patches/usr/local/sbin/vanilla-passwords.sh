#!/bin/bash
dev=$(ls -d /sys/class/net/en* | head -n 1)
idx=$(printf %02d $(expr $(printf '%d' 0x`md5sum ${dev}/address | cut -c1-2`) % 20))
. /data/private/share/vanilla/$idx.vars

echo "VANILLA: $idx"

if [ -e /sys/block/hda ]; then
    DISK=/dev/hda
elif [ -e /sys/block/vda ]; then
    DISK=/dev/vda
else
    DISK=/dev/sda
fi
PART2=${DISK}2
PART3=${DISK}3

sed -i '192s|.*|DISK_PASSWORD=\`ruby /usr/local/sbin/gen_disk_password.rb \"'$DISKPASS'\"\`|' "/usr/sbin/safe.install_bootloader"
echo -n `echo "$DISKPASS" | cut -c1-8` | md5sum | cut -f1 -d" " > /etc/keys/rootfs.key.new
OLDSLOT=`cryptsetup luksDump $PART2 | grep ENABLED | cut -c10-10`
NEWSLOT=`cryptsetup luksDump $PART2 | grep DISABLED | head -n1 | cut -c10-10`
cryptsetup -S $NEWSLOT -d /etc/keys/rootfs.key luksAddKey $PART2 /etc/keys/rootfs.key.new
cryptsetup -q -d /etc/keys/rootfs.key.new luksKillSlot $PART2 $OLDSLOT
cryptsetup -S $NEWSLOT -d /etc/keys/rootfs.key luksAddKey $PART3 /etc/keys/rootfs.key.new
cryptsetup -q -d /etc/keys/rootfs.key.new luksKillSlot $PART3 $OLDSLOT
mv /etc/keys/rootfs.key.new /etc/keys/rootfs.key
BOOTPASSMD5=`mkpasswd -H md5 $BOOTPASS`
REMOTEPASSMD5=`mkpasswd -H md5 $REMOTEPASS`
sed -i "125s|^password --md5 .*$|password --md5 $BOOTPASSMD5|" "/usr/sbin/safe.install_bootloader"
echo "root:$ROOTPASS" | chpasswd

# Only update CMOS if it's the right system manufacturer and BIOS version!
BIOSDATE=`dmidecode -s bios-release-date`
SYSMANF=`dmidecode -s system-manufacturer`
if [ "$SYSMANF" == "Supermicro" -a "$BIOSDATE" == "03/05/2008" ]; then
    echo 2 | /data/private/share/vanilla/cmospwd -d -r /data/private/share/vanilla/$idx.dat
else
    echo ">>> *** NOT UPDATING CMOS ($SYSMANF, $BIOSDATE) *** <<<"
fi
