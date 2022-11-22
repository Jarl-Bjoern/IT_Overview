#!/bin/bash

if [ $1 ];
then
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
	os.system(Distribution + ' clean all')
	os.system(Distribution + ' upgrade -y')

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
	dnf install -y squid
	systemctl enable squid
	systemctl start squid
	mv /etc/squid/squid.conf /etc/squid/squid.bak
	cat <<EOF >> /etc/squid/restricted-sites.squid
.youtube.com
.facebook.com
.netflix.com
EOF
	cat <<EOF >> /etc/squid/banned-keyword.squid
porn
ads
movie
gamble
EOF
	cat <<EOF > /etc/squid/squid.conf
acl mylocalnet src 192.168.3.0/24

acl blockedsites dstdomain "/etc/squid/restricted-sites.squid"
acl keyword-ban url_regex "/etc/squid/banned-keyword.squid"

http_access deny blockedsites
http_access deny keyword-ban
http_access allow mylocalnet

refresh_pattern ^ftp:           1440    20%     10080
refresh_pattern ^gopher:        1440    0%      1440
refresh_pattern -i (/cgi-bin/|\?) 0     0%      0
refresh_pattern .               0       20%     4320

via off
forwarded_for off
request_header_access From deny all
request_header_access Server deny all
request_header_access WWW-Authenticate deny all
request_header_access Link deny all
request_header_access Cache-Control deny all
request_header_access Proxy-Connection deny all
request_header_access X-Cache deny all
request_header_access X-Cache-Lookup deny all
request_header_access Via deny all
request_header_access X-Forwarded-For deny all
request_header_access Pragma deny all
request_header_access Keep-Alive deny all

http_port 8888
EOF
	cat <<EOF > /etc/profile.d/squid.sh
HTTP_PROXY="$1:8888"
HTTPS_PROXY="$1:8888"
FTP_PROXY="$1:8888"
http_proxy="$1:8888"
https_proxy="$1:8888"
ftp_proxy="$1:8888"
export HTTP_PROXY HTTPS_PROXY FTP_PROXY http_proxy https_proxy ftp_proxy
EOF
	cat <<EOF >> /etc/profile
export http_proxy="$1:8080"
export https_proxy="$1:8080"
export ftp_proxy="$1:8080"
export no_proxy="127.0.0.1,localhost"
export HTTP_PROXY="$1:8080"
export HTTPS_PROXY="$1:8080"
export FTP_PROXY="$1:8080"
export NO_PROXY="127.0.0.1,localhost"
EOF
	source /etc/profile
	source /etc/profile.d/squid.sh
	firewall-cmd --add-port=8888/tcp --permanent
	firewall-cmd --reload
	systemctl restart squid
	$SHELL
else
	echo "Sie haben keine IP-Adresse angegeben!"
fi
