#!/bin/bash

if [ $1 ];
then
	function finish {
		shred -u $0
	}
	yum update -y
	mkdir /etc/scripts
	touch /etc/scripts/update.py
	chmod -R 750 /etc/scripts
	cat <<EOF > /etc/scripts/update.py
import os, random, subprocess, time

CentOS = subprocess.getoutput('cat /etc/*release | grep CentOS')
Fedora = subprocess.getoutput('cat /etc/*release | grep Fedora')
Zufall = random.randint(10, 300)

def Updater(Distribution):
	os.system(Distribution + ' update -y')
	os.system(Distribution + ' upgrade -y')
	os.system(Distribution + ' clean all')

time.sleep(Zufall)
if (CentOS != ""):
	Updater('yum')
elif (Fedora != ""):
	Updater('dnf')
else:
	Updater('dnf')
EOF
	echo "* 2 * * * root python3 /etc/scripts/update.py" >> /etc/crontab
	if [´cat /etc/*release | grep CentOS´];	
	then
		dnf install -y epel-release
		yum config-manager --set-enabled powertools
		dnf update -y
		dnf group install -y "Development Tools"
	elif [´cat /etc/*release | grep Fedora´];
	then
		dnf install -y g++
	fi
	yum install -y openssl openssl-devel libcurl-devel zlib-devel libpng-devel libxml2-devel json-c-devel bzip2-devel pcre2-devel ncurses-devel
	yum install -y clamav-update clamd
	cd ~/Downloads
	wget https://www.clamav.net/downloads/production/clamav-0.103.1.tar.gz
	tar -xzvf clamav-*.tar.gz
	echo "y" | rm clamav-0.103.1.tar.gz
	cd clamav.*
	./configure ; make -j2 ; make install
	cp /usr/local/etc/freshclam.conf.sample /usr/local/etc/freshclam.conf
	sed -i s/Example/#Example/g /usr/local/etc/freshclam.conf
	cat <<EOF >> /usr/local/etc/freshclam.conf
LogTime yes
LogRotate yes
DatabaseOwner clamav
EOF
	setsebool -P antivirus_can_scan_system 1
	groupadd clamav
	useradd -g clamav -s /bin/false clamav
	useradd -g clamav -s /bin/false clamscan
	freshclam
	sed -i 's/#LocalSocket \/run/ clamd.scan/clamd.sock /LocalSocket \/run/clamd.scan/clamd.sock/g' /etc/clamd.d/scan.conf
	sed -i 's/scanner (%i) daemon/scanner daemon/g' /usr/lib/systemd/system/clamd@.service
	sed -i 's/\/etc\/clamd.d\/%i.conf/\/etc\/clamd.d\/scan.conf/g' /usr/lib/systemd/system/clamd@.service
	cat <<EOF > /usr/lib/systemd/system/clam-freshclam.service
[Unit]
Description=freshclam scanner
After=network.target

[Service]
Type=forking
ExecStart=/usr/bin/freshclam -d -c 4
Restart=on-failure
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
	systemctl enable clam-freshclam.service
	systemctl start clam-freshclam.service
	sed -i 's/#OnAccessPrevention yes/OnAccessPrevention yes/g' /etc/clamd.d/scan.conf
	sed -i 's/#OnAccessIncludePath \/home/OnAccessIncludePath \/home/g' /etc/clamd.d/scan.conf
	echo "OnAccessIncludePath /var/www/html" >> /etc/clamd.d/scan.conf
	sed -i 's/#OnAccessExcludeUname clamav/OnAccessExcludeUname clamscan/g' /etc/clamd.d/scan.conf
	mkdir -p /etc/clamav/log
	touch /etc/clamav/log/clamonacc
	chmod 600 /etc/clamav/log/clamonacc
	chown clamav /etc/clamav/log/clamonacc
	mkdir /tmp/clamav-quaratine
	systemctl daemon-reload
	systemctl enable clamd@.service
	systemctl start clamd@service
	systemctl enable clamd@scan
	systemctl start clamd@scan
	yum install -y vsftpd
	systemctl enable vsftpd
	systemctl start vsftpd
	firewall-cmd --zone=public --permanent --add-port=20-21/tcp
	firewall-cmd --zone=public --permanent --add-port=30000-31000/tcp
	firewall-cmd --zone=public --permanent --add-service=ftp
	firewall-cmd --reload
	useradd ftpuser -p $1
	mkdir -p /home/ftpuser/backup
	chmod -R 750 /home/ftpuser/backup
	chown -R ftpuser: /home/ftpuser/backup
	cp /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.bak
	echo "ftpuser" | tee -a /etc/vsftpd/user_list
	openssl req -newkey rsa:4096 -nodes -keyout /etc/vsftpd.pem -x509 -days 365 -out /etc/vsftpd/vsftpd.pem -subj "/C=DE/ST=Germany/L=Germany/O=Security/OU=IT Department/CN=www.example.com"
	cat <<EOF >> /etc/vsftpd/vsftpd.conf
userlist_deny=NO
chroot_local_user=YES
pasv_min_port=30000
pasv_max_port=31000
rsa_cert_file=/etc/vsftpd/vsftpd.pem
rsa_private_key_file=/etc/vsftpd.pem
ssl_enable=YES
EOF
	systemctl restart vsftpd
	$SHELL
	trap finish EXIT
else
	echo "Es wurde kein Passwort angegeben!"
fi
