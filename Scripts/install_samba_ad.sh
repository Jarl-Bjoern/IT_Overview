#!/bin/bash

if [ $1 ] && [ $2 ] && [ $3 ] && [ $4 ] && [ $5 ] && [ $6 ] && [ $7 ];
then
	mkdir /etc/scripts
	touch /etc/scripts/update.py /etc/scripts/ersatz.py
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
	cat <<EOF > /etc/scripts/ersatz.py
Liste_Stelle = []

Datei = open('/root/.bash_profile', 'r')
Text = Datei.readlines()
Datei.close()

for i in Text:
	if ("PATH" in i):
		Neue_Stelle = '#' + i
		if (Neue_Stelle not in Liste_Stelle):
			Liste_Stelle.append(Neue_Stelle)
	else:
		Liste_Stelle.append(i)

with open('/root/.bash_profile', 'w') as f:
	for i in Liste_Stelle:
		f.write(i)
	f.close()
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
	yes y | rm /etc/krb5.conf
	yum install -y epel-release
	yum install -y dnf-plugins-core
	yum config-manager --set-enabled devel powertools -y
	yum install -y --setopt=install_weak_deps=False "@Development Tools" acl attr autoconf avahi-devel bind-utils binutils bison ccache chrpath cups-devel curl dbus-devel docbook-dtds docbook-style-xsl flex gawk gcc gdb git glib2-devel glibc-common glibc-langpack-en glusterfs-api-devel glusterfs-devel gnutls-devel gpgme-devel gzip hostname htop jansson-devel keyutils-libs-devel krb5-devel krb5-server libacl-devel libarchive-devel libattr-devel libblkid-devel libbsd-devel libcap-devel libcephfs-devel libicu-devel libnsl2-devel libpcap-devel libtasn1-devel libtasn1-tools libtirpc-devel libunwind-devel libuuid-devel libxslt lmdb lmdb-devel make mingw64-gcc ncurses-devel openldap-devel pam-devel patch perl perl-Archive-Tar perl-ExtUtils-MakeMaker perl-Parse-Yapp perl-Test-Simple perl-generators perl-interpreter pkgconfig popt-devel procps-ng psmisc python3 python3-cryptography python3-devel python3-dns python3-gpg python3-libsemanage python3-markdown python3-policycoreutils python3-pyasn1 quota-devel readline-devel redhat-lsb rng-tools rpcgen rpcsvc-proto-devel rsync sed sudo systemd-devel tar tree wget which xfsprogs-devel yum-utils zlib-devel
	yum clean all
	wget https://download.samba.org/pub/samba/stable/samba-4.13.4.tar.gz -O ~/samba.tar.gz
	tar -xzvf samba.tar.gz
	mv samba-4.13.4 samba
	cd samba
	./configure
	make
	make install
	python3 /etc/scripts/ersatz.py
	echo "PATH=/usr/local/samba/bin/:/usr/local/samba/sbin/:$PATH" >> ~/.bash_profile
	. ~/.bash_profile
	rm ~/samba.tar.gz /etc/scripts/ersatz.py
	echo "$6 samba-ad samba-ad.$3" >> /etc/hosts
	printf "$3\n.\$4\.\8.8.8.8\n$5\n$5" | samba-tool domain provision --use-rfc2307 --interactive --option="interfaces=$1" --option="bind interfaces only=$2"
	samba
	cat <<EOF > /etc/systemd/system/samba-ad-dc.service
[Unit]
Description=Samba Service for AD DC
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
ExecStart=/usr/local/samba/sbin/samba -D
PIDFILE=/usr/local/samba/var/run/samba.pid
ExecReload=/bin/kill -HUP $MAINPID

[Install]
WantedBy=multi-user.target
EOF
	samba-tool dns zonecreate $6 $7.in-addr.arpa -U root
	cp /usr/local/samba/private/krb5.conf /etc/krb5.conf
	$SHELL
else
	echo "Es wurden nicht alle Paramter angegeben!\n\n1. Netzwerkinterface:\n2. Bind interfaces only: yes/no\n3. Domänenname:\n4. Server Rolle:\n5. Admin Passwort:\n6. IP-Adresse des Servers:\n7. Reverse Zone"
fi
