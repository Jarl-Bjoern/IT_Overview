#!/bin/bash

if [ $1 ];
then
	function finish {
		shred -u $0
	}
	mkdir /etc/.scripts
	touch /etc/.scripts/update.py /etc/.scripts/ersatz.py /etc/.scripts/steuerung_selenium.py /etc/.scripts/scan.py
	chmod -R 750 /etc/.scripts
	cat <<EOF > /etc/.scripts/update.py
import os, random, subprocess, time

CentOS = subprocess.getoutput('cat /etc/*release | grep CentOS')
Fedora = subprocess.getoutput('cat /etc/*release | grep Fedora')
Zufall = random.randint(10, 300)

def Updater(Distribution):
	os.system(Distribution + ' update -y')
	os.system(Distribution + ' upgrade -y')
	os.system('freshclam')
	os.system(Distribution + ' clean all')

time.sleep(Zufall)
if (CentOS != ""):
	Updater('yum')
elif (Fedora != ""):
	Updater('dnf')
else:
	Updater('dnf')
EOF
	cat <<EOF > /etc/.scripts/ersatz.py
Datei = open('/opt/mailcow-dockerized/docker-compose.yml', 'r')
Text = Datei.readlines()
Datei.close()

Neue_Datei = open('/opt/mailcow-dockerized/docker-compose_ersatz.yml', 'w')
for i in Text:
	if ('enable_ipv6: true' in i):
		x = i.replace('enable_ipv6: true', 'enable_ipv6: false')
		Neue_Datei.write(x)
	else:
		Neue_Datei.write(i)
Neue_Datei.close()
EOF
	pip3 install -y selenium
	wget https://chromedriver.storage.googleapis.com/89.0.4389.23/chromedriver_linux64.zip
	unzip chromedriver_linux64.zip
	rm chromedriver_linux64.zip -y
	cat <<EOF > /etc/.scripts/steuerung_selenium.py
from selenium import webdriver
from selenium.webdriver import ActionChains

Pfad_Chrome = "~/chromedriver"
EOF
	echo "* 2 * * * root python3 /etc/.scripts/update.py" >> /etc/crontab
	yum remove runc -y
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
	cp /etc/clamd.d/scan.conf /usr/local/etc/clamd.conf
	cat <<EOF > /usr/lib/systemd/system/clamonacc.service
[Unit]
Description=ClamAV On Access Scanner
Requires=clamd@service
After=clamd.service syslog.target network-online.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/sbin/clamonacc -F --log=/etc/clamav/log/clamonacc --move=/tmp/clamav-quarantine
Restart=on-failure
RestartSec=7s

[Install]
WantedBy=multi-user.target
EOF
	cat <<EOF > /usr/lib/systemd/system/sc.service
[Unit]
Description=ClamAV Scanner
After=network-online.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 /etc/.scripts/scan.py
PIDFile=/run/sc_scan.pid
Restart=always
RestartSec=43200s

[Install]
WantedBy=multi-user.target
EOF
	systemctl daemon-reload
	systemctl enable clamd@.service
	systemctl start clamd@service
	systemctl enable clamd@scan
	systemctl start clamd@scan
	systemctl enable clamonacc.service
	systemctl start clamonacc.service
	systemctl enable sc.service
	systemctl start sc.service
	yum update -y
	curl -sSl https://get.docker.com/ | CHANNEL=stable sh
	systemctl enable docker
	systemctl start docker
	curl -L https://github.com/docker/compose/releases/download/$(curl -Ls https://www.servercow.de/docker-compose/latest.php)/docker-compose-$(uname -s)-$(uname -m) > /usr/local/bin/docker-compose
	chmod +x /usr/local/bin/docker-compose
	cat <<EOF > /etc/docker/daemon.json
{
	"selinux-enabled": true
}
EOF
	umask 0022
	yum install git -y
	cd /opt
	git clone https://github.com/mailcow/mailcow-dockerized
	cd mailcow-dockerized
	printf "$1\nY" | ./generate_config.sh
	python3 /etc/scripts/ersatz.py
	mv docker-compose.yml docker-compose.bak
	mv docker-compose_ersatz.yml docker-compose.yml
	rm /etc/scripts/ersatz.py /etc/scripts/steuerung_selenium.py ~/chromedriver
	docker-compose pull
	docker-compose up -d
	pip3 uninstall -y selenium
	$SHELL
	trap finish EXIT
else
	echo "Sie haben keinen Domänennamen angegeben!"
fi
