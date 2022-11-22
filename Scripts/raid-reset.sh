if [ `cat /proc/mdstat | grep resync | cut -d" " -f9`] ; then
{
	echo "Das RAID-System befindet sich bereits in einem Wiederaufbau!"
	echo "false" > /usr/bin/xvR.txt
}
else
{
	if [ `cat /usr/bin/xvR.txt | grep true` ] ; then
	{
		umount /dev/md0
		mdadm --stop /dev/md0
		F1="/dev/"`ls -al /dev/disk/by-id | grep "00800-0:0-part1" | cut -d"/" -f3`
		F2="/dev/"`ls -al /dev/disk/by-id | grep "00800-0:0-part2" | cut -d"/" -f3`
		F3="/dev/"`ls -al /dev/disk/by-id | grep "15221-0:0-part3" | cut -d"/" -f3`
		F4="/dev/"`ls -al /dev/disk/by-id | grep "15221-0:0-part4" | cut -d"/" -f3`
		HS1="/dev/"`ls -al /dev/disk/by-id | grep "15221-0:0-part1" | cut -d"/" -f3`
		HS2="/dev/"`ls -al /dev/disk/by-id | grep "15221-0:0-part2" | cut -d"/" -f3`
		mdadm --zero-superblock $F1
		mdadm --zero-superblock $F2
		mdadm --zero-superblock $F3
		mdadm --zero-superblock $F4
		mdadm --zero-superblock $HS1
		mdadm --zero-superblock $HS2
		echo "yes" | mdadm --create /dev/md0 --level=10 --raid-devices=4 $F1 $F2 $F3 $F4
		echo "yes" | mkfs.ext4 -b 4096 -E stride=128,stripe-width=256 /dev/md0
		su -c "/usr/share/mdadm/mkconf > /etc/mdadm/mdadm.conf"
		touch /etc/mdadm/mdadm_p.conf
		touch /etc/mdadm/t.conf
		chmod 666 /etc/mdadm/mdadm_p.conf
		chmod 666 /etc/mdadm/t.conf
		cat /etc/mdadm/mdadm.conf | grep HOME > /etc/mdadm/mdadm_p.conf
		mdadm --detail /dev/md0 | grep Version | cut -d: -f2 > /etc/mdadm/t.conf
		META=`cat /etc/mdadm/t.conf | cut -d" " -f2`
		mdadm --detail /dev/md0 | grep UUID | cut -d: -f2-5 > /etc/mdadm/t.conf
		UUID=`cat /etc/mdadm/t.conf | cut -d" " -f2`
		echo "ARRAY /dev/md/0 metadata=$META UUID=$UUID" >> /etc/mdadm/mdadm_p.conf
		mv /etc/mdadm/mdadm_p.conf /etc/mdadm/mdadm.conf
		chmod 644 /etc/mdadm/mdadm.conf
		rm /etc/mdadm/t.conf
		update-initramfs -u
		mount -a
		mdadm /dev/md0 --add $HS1
		mdadm /dev/md0 --add $HS2
		echo "false" > /usr/bin/xvR.txt
		Datum=`date +'%A %d.%m.%Y %H:%M:%S'`
		echo "Letzter Neuaufbau: $Datum\n" >> /var/log/rreset.log
	}
	fi
}
fi
