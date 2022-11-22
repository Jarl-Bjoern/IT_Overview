#!/bin/bash

if [ $1 ] && [ $2 ] && [ $3 ] && [ $4 ] && [ $5 ] && [ $6 ] && [ $7 ] && [ $8 ] && [ $9 ];
then
	yum update -y
	mkdir /etc/scripts
	touch /etc/scripts/update.py
	chmod -R 750 /etc/script
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
	yum install gcc pcre-devel tar make -y
	wget http://www.haproxy.org/download/2.0/src/haproxy-2.0.7.tar.gz -O /etc/haproxy.tar.gz
	tar xzvf /etc/haproxy.tar.gz -C /etc/
	cd /etc/haproxy-2.0.7
	make TARGET=linux-glibc
	make install
	mkdir -p /etc/haproxy /var/lib/haproxy
	touch /var/lib/haproxy/stats
	ln -s /usr/local/sbin/haproxy /usr/sbin/haproxy
	useradd -r haproxy
	groupadd haproxy
	firewall-cmd --permanent --zone=public --add-service=http
	firewall-cmd --permanent --zone=public --add-port=8181/tcp
	firewall-cmd --reload
	cat <<EOF > /etc/haproxy/haproxy.cfg
global
	log /dev/log local0
	log /dev/log local1 notice
	chroot /var/lib/haproxy
	stats timeout 30s
	user haproxy
	group haproxy
	daemon

defaults
	log global
	mode http
	option httplog
	option dontlognull
	timeout connect 5000
	timeout client 50000
	timeout server 50000
EOF
	if [ "$1" == "4" ];
	then
		cat <<EOF >> /etc/haproxy/haproxy.cfg
frontend http_front
	bind *:80
	stats uri /haproxy?stats
	default_backend http_back

backend http_back
	balance roundrobin
	server $4 $5:80 check
	server $6 $7:80 check

EOF
	elif [ "$1" == "7" ];
	then
		cat <<EOF >> /etc/haproxy/haproxy.cfg
frontend http_front
	bind *:80
	stats uri /haproxy?stats
	acl url_blog path_beg /blog
	use_backend blog_back if url_blog
	default_backend http_back

backend http_back
	balance roundrobin
	server $4 $5:80 check
	server $6 $7:80 check

backend blog_back
	server $8 $9:80 check
EOF
	fi
	cat <<EOF >> /etc/haproxy/haproxy.cfg
listen stats
	bind *:8181
	stats enable
	stats uri /
	stats realm Haproxy\ Statistics
	stats auth $2:$3
EOF
	cp /etc/haproxy-2.0.7/examples/haproxy.init /etc/init.d/haproxy
	chmod 750 /etc/init.d/haproxy
	systemctl daemon-reload
	chkconfig haproxy on
	service haproxy restart
	rm -r /etc/haproxy.tar.gz
	$SHELL
else
    	printf "Es wurden nicht alle Parameter angegeben!\n\nReihenfolge der Angaben\n\nLayer:\nBenutzername:\nPasswort:\nServer Name 1:\nIP-Adresse des Servers 1:\nServer Name 2:\nIP-Adresse des Servers 2:\nServer Name 3:\nIP-Adresse des Servers 3:\n\n"
fi
