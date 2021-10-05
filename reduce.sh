#!/bin/bash

file=$1
device="/dev/loop10"
partition="/dev/mapper/loop10p1"

sudo losetup ${device} ${file}
sudo kpartx -av ${device}
sudo fsck -fy ${partition}
sudo resize2fs -f -M ${partition}

old_disk_size=$(sudo blockdev --getsize64 ${device})
bc=$(sudo dumpe2fs -h ${partition} 2>&1 | grep 'Block count' | awk '{print $3}')
bs=$(sudo dumpe2fs -h ${partition} 2>&1 | grep 'Block size'  | awk '{print $3}')
fs_size=$((${bc}*${bs}))
new_disk_size=$((2048*512+${fs_size}))
size_diff=$((${old_disk_size}-${new_disk_size}))

sudo kpartx -dv ${device}

sudo parted "${device}" ---pretend-input-tty <<EOF
resizepart
1
${new_disk_size}B
Yes
quit
EOF
sudo losetup -d ${device}
sudo truncate --size="-${size_diff}" "${file}"
echo "Old: $old_disk_size New: $new_disk_size"
