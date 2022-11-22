#!/bin/bash

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
dnf install -y epel-release
dnf install -y openvpn easy-rsa
mkdir /home/admin/easy-rsa
ln -s /usr/share/easy-rsa/3/* /home/admin/easy-rsa
chown admin /home/admin/easy-rsa
chmod 700 /home/admin/easy-rsa
cat <<EOF > /home/admin/easy-rsa/vars
set_var EASYRSA_ALGO "ec"
set_var EASYRSA_DIGEST "sha512"
EOF
cd /home/admin/easy-rsa
./easyrsa init-pki
printf "\n" | ./easyrsa gen-req server nopass
cp /home/admin/easy-rsa/pki/private/server.key /etc/openvpn/server
scp /home/admin/easy-rsa/pki/reqs/server.req admin@192.168.3.20:/tmp
cp /tmp/{server.crt,ca.crt} /etc/openvpn/server
openvpn --genkey --secret ta.key
cp ta.key /etc/openvpn/server
mkdir -p /home/admin/client-configs/keys
chmod -R 700 /home/admin/client-configs
./easyrsa gen-req client1 nopass
cp pki/private/client1.key /home/admin/client-configs/keys/
scp pki/reqs/client1.req admin@192.168.3.20:/tmp
cp /tmp/client1.crt /home/admin/client-configs/keys
cp /home/admin/easy-rsa/ta.key /home/admin/client-configs/keys
cp /etc/openvpn/server/ca.crt /home/admin/client-configs/keys
chown -R admin /home/admin/client-configs
cp /usr/share/doc/openvpn/sample/sample-config-files/server.conf /etc/openvpn/server
sed -i s/"tls-auth ta.key 0 # This file is secret"/"tls-crypt ta.key"/g /etc/openvpn/server/server.conf
sed -i s/"cipher AES-256-CBC"/"cipher AES-256-GCM"/g /etc/openvpn/server/server.conf
sed -i s/"dh dh2048.pem"/"dh none"/g /etc/openvpn/server/server.conf
sed -i s/";user nobody"/"user nobody"/g /etc/openvpn/server/server.conf
sed -i s/";group nobody"/"group nobody"/g /etc/openvpn/server/server.conf
echo "auth SHA256" >> /etc/openvpn/server/server.conf
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p
firewall-cmd --permanent --zone=trusted --add-interface=tun0
firewall-cmd --permanent --add-service=openvpn
firewall-cmd --permanent --zone=trusted --add-service=openvpn
firewall-cmd --reload
firewall-cmd --add-masquerade --permanent
DEVICE=$(ip route | awk '/^default via/ {print $5}')
firewall-cmd --permanent --direct --passthrough ipv4 -t nat -A POSTROUTING -s 192.168.3.0/24 -o $DEVICE -j MASQUERADE
systemctl -f enable openvpn-server@server.service
systemctl start openvpn-server@server.service
mkdir -p /home/admin/client-configs/files
cp /usr/share/doc/openvpn/sample/sample-config-files/client.conf /home/admin/client-configs/base.conf
sed -i s/"tls-auth ta.key 1"/";tls-auth ta.key 1"/g /home/admin/client-configs/base.conf
sed -i s/"cipher AES-256-CBC"/"cipher AES-256-GCM"/g /home/admin/client-configs/base.conf
sed -i s/"ca ca.crt"/";ca ca.crt"/g /home/admin/client-configs/base.conf
sed -i s/"cert client.crt"/";cert client.crt"/g /home/admin/client-configs/base.conf
sed -i s/"key client.key"/";key client.key"/g /home/admin/client-configs/base.conf
sed -i s/"user nobody"/";user nobody"/g /home/admin/client-configs/base.conf
sed -i s/"group nobody"/";group nobody"/g /home/admin/client-configs/base.conf
printf "remote 192.168.3.1 1194\nkey-direction 1\nauth SHA256" >> /home/admin/client-configs/base.conf
cat <<EOF > /home/admin/client-configs/make_config.sh
#!/bin/bash
KEY_DIR=/home/admin/client-configs/keys
OUTPUT_DIR=/home/admin/client-configs/files
BASE_CONFIG=/home/admin/client-configs/base.conf
cat ${BASE_CONFIG} \
<(echo -e '<ca>') \
${KEY_DIR}/ca.crt \
<(echo -e '</ca>\n<cert>') \
${KEY_DIR}/${1}.crt \
<(echo -e '</cert>\n<key>') \
${KEY_DIR}/${1}.key \
<(echo -e '</key>\n<tls-crypt>') \
${KEY_DIR}/ta.key \
<(echo -e '</tls-crypt>') \
> ${OUTPUT_DIR}/${1}.ovpn
EOF
cd /home/admin/client-configs
chmod 750 make_config.sh
bash make_config.sh client1
$SHELL
