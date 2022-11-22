RAID=`sudo cat /proc/mdstat | grep md`
HS=`sudo mdadm -D /dev/md0 | grep spare | grep /dev/sd`
BLOCK=`sudo cat /usr/bin/blocked.txt | grep true`

if [ !$HS ] ; then
{
	echo "Die Hot-Spare Partitionen wurden aufgebraucht!" > /usr/bin/check.txt 
	if [ !$RAID ] ; then
	{ 
		echo "Das Raid-System funktioniert nicht mehr!" >> /usr/bin/check.txt 
	}
	fi
	sudo python3 /usr/bin/mail-warning.py
} elif [ $BLOCK ] ; then
{
	sudo cat /usr/bin/user.txt >> /usr/bin/check.txt
	sudo python3 /usr/bin/mail-warning.py
	echo “false“ > /usr/bin/blocked.txt
}
fi
