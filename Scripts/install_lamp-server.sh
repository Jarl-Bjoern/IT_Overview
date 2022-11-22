#!/bin/bash

if [ $1 ] && [ $2 ] && [ $3 ] && [ $4 ] && [ $5 ] && [ $6 ] && [ $7 ] && [ $8 ] && [ $9 ] && [ $10 ] && [ $11 ];
then
	mkdir /etc/scripts
	touch /etc/scripts/update.py /etc/scripts/ersatz.py /etc/scripts/db_config.py
	chmod -R 750 /etc/scripts
	touch /etc/scripts/.dbs /etc/scripts/.pw
	chmod 600 /etc/scripts/.dbs /etc/scripts/.pw
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
	cat <<EOF > /etc/scripts/db_config.py
import os, sys

with open (str(sys.argv[1]), 'r') as f:
	Text = f.readlines()
	PW = Text[0].split('\n')
f.close()

Datei = open(str(sys.argv[2]), 'r')
Text = Datei.readlines()
Datei.close()

def Datenbank_OS_Version(Kommandos = ""):
	for i in Text:
		Kommandos += (str(i.split('\n')[0]))
	os.system('mysql -h "localhost" -u "root" "-p"+PW[0] sys.argv[3] -Bse '+'"'+Kommandos+'"')

if __name__ == '__main__':
#	Datenbank_Eintraege()
	Datenbank_OS_Version()
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
	dnf install -y httpd
	systemctl start httpd
	firewall-cmd --permanent --add-service=http
	firewall-cmd --reload
	yum install -y bind*
	systemctl enable named
	systemctl start named
	cp /etc/named.conf /etc/named.bak
	touch /var/named/fwd.$4.db /var/named/rev.$6.db
	chmod 660 /var/named/fwd.$4.db /var/named/rev.$6.db
	chown root.named /var/named/fwd.$4.db /var/named/rev.$6.db
	echo '$TTL 86400' > /var/named/fwd.$4.db
	cat <<EOF >> /var/named/fwd.$4.db
@ IN SOA $8.$4. root.$4. (
			1 ;Serial
			3600 ;Refresh
			1800 ;Retry
			604800 ;Expire
			43200 ;Minimum TTL
)

@	IN	NS	$8.$4.
$8	IN	A	$1
www	IN	CNAME	$8
EOF
	echo '$TTL 86400' > /var/named/rev.$6.db
	cat <<EOF >> /var/named/rev.$6.db
@ IN SOA $8.$4. root.$4. (
			1 ;Serial
			3600 ;Refresh
			1800 ;Retry
			604800 ;Expire
			86400 ;Minimum TTL
)

@	IN	NS	$8.$4.
1	IN	PTR	$8.$4.
2	IN	PTR	www.$4.
EOF
	echo 'OPTIONS="-4"' >> /etc/sysconfig/named
	sed -i s/"listen-on-v6 port 53 { ::1; };/#listen-on-v6 port 53 { ::1; };"/g /etc/named.conf
	sed -i s/"listen-on port 53 { 127.0.0.1; };/listen-on port 53 { 127.0.0.1; $1; };"/g /etc/named.conf
	sed -i s/"allow-query     { localhost; };/allow-query     { localhost; $2/24; };"/g /etc/named.conf
	sed -i s/"recursion yes;/recursion $3;"/g /etc/named.conf
	cat <<EOF >> /etc/named.conf
zone "$4" IN {
	type master;
	file "fwd.$4.db";
	allow-update { $5; };
};

zone "$6.in-addr.arpa" IN {
	type master;
	file "rev.$6.db";
	allow-update { $7; };
};
EOF
	systemctl restart named.service
	firewall-cmd --add-service=dns --zone=public --permanent
	firewall-cmd --zone=public --permanent --add-rich-rule='rule family="ipv4" source address="192.168.3.0/24" port protocol="udp" port="53" accept'
	firewall-cmd --reload
	dnf install -y mariadb-server iptables-service
	systemctl enable mariadb
	systemctl start mariadb
	mysql_secure_installation <<EOF

y
$11
$11
y
y
y
y
EOF
	cat <<EOF > /etc/scripts/.dbs
CREATE USER 'herold'@'localhost' IDENTIFIED BY 'test1234';
CREATE DATABASE TestDatenbank;
GRANT ALL ON TestDatenbank.* TO 'herold'@'localhost' IDENTIFIED BY 'test1234' WITH GRANT OPTION;
FLUSH PRIVILEGES;
CREATE TABLE TestDatenbank.todo_list ( item_id INT AUTO_INCREMENT, content VARCHAR(255), PRIMARY KEY(item_id));
INSERT INTO TestDatenbank.todo_list (content) VALUES ("Lernen");
EOF
	cat <<EOF > /etc/scripts/.pw
test1234
EOF
	python3 /etc/scripts/db_config.py "/etc/scripts/.pw" "/etc/scripts/.dbs" "TestDatenbank"
	dnf install -y php php-mysqlnd
	systemctl restart httpd
	mkdir -p /var/www/html/$4/style /var/www/html/$4/pages/usr
	cat <<EOF > /var/www/html/$4/pages/usr/pw.txt
$11
EOF
	cat <<EOF > /var/www/html/$4/header.php
<html>
<head>
	<link rel="stylesheet" type="text/css" href="style/design.css" >
	<title> Index </title>
</head>
<body>
EOF
	cat <<EOF > /var/www/html/$4/footer.php
</body>
<article>
<footer>
	<hr>
	<p><h2>Copyright: Rainer Herold</h2></p>
</footer>
</article>
</html>
EOF
	cat <<EOF > /var/www/html/$4/index.php
<?php
session_start();

# Kopfzeile
require_once("header.php");

# Body_Bereich
require_once("pages/"."startseite.php");

# Fußzeile
require_once("footer.php");
?>
EOF
	cat <<'EOF' > /var/www/html/$4/pages/startseite.php
<h1>LAMP-Server</h1>
<hr> <?php
$Datei = fopen("pages/usr/pw.txt", "r") or die ("Die Datei lässt sich nicht öffnen!");
$Text = fread($Datei, filesize("pages/usr/pw.txt"));
$pw = preg_replace('/\s+/', '', $Text);

$user = "herold";
$password = '$pw';
$database = "TestDatenbank";
$table = "todo_list";

try {
	$con = new PDO("mysql:host=localhost;dbname='$database'", $user, $password);
	echo "<h2>TODO</h2><ol>";
	foreach($con->query("SELECT content FROM $table") as $row) {
		echo "<li>" . $row['content'] . "</li>";
	}
	echo "</ol>";
} catch (PDOException $e) {
	print "Error!: " . $e->getMessage() . "<br/>";
	die();
} ?>
EOF
	cat <<EOF > /var/www/html/$4/style/design.css
h1 {
	color: white;
	text-align: center;
}
h2 {
	color: white;
	text-align: center;
}
html {
	background-color: 0082C9;
}
EOF
	echo "LoadModule rewrite_module modules/mod_rewrite.so" >> /etc/httpd/conf.modules.d/00-base.conf
	cat <<EOF > /var/www/html/$4/.htaccess
#RewriteEngine on
#RewriteBase /
#RewriteRule ^index\.php$ - [L]
#RewriteCond %{REQUEST_FILENAME} !-f
#RewriteCond %{REQUEST_FILENAME} !-d
#RewriteRule . /index.php [L]
EOF
	cd /var/www/html/$4
	chmod 660 footer.php header.php style/design.css
	chmod 600 pages/usr/pw.txt
	chmod 700 pages/usr
	chmod 750 pages
	mkdir /etc/httpd/sites-available /etc/httpd/sites-enabled
	dnf install -y httpd mod_ssl
	systemctl enable --now httpd
	firewall-cmd --add-port=443/tcp --permanent
	firewall-cmd --reload
	openssl req -newkey rsa:4096 -nodes -keyout /etc/pki/tls/private/kifarunix-demo.key -x509 -days 365 -out /etc/pki/tls/certs/kifarunix-demo.cr -subj "/C=DE/ST=Germany/L=Germany/O=Security/OU=IT Department/CN=www.example.com"
	sed -i s/"SSLCertificateKeyFile /etc/pki/tls/private/localhost.key/SSLCertificateKeyFile /etc/pki/tls/private/kifarunix-demo.key"/g /etc/httpd/conf.d/ssl.conf
	sed -i s/"SSLCertificateFile /etc/pki/tls/certs/localhost.crt /SSLCertificateFile /etc/pki/tls/certs/kifarunix-demo.crt"/g /etc/httpd/conf/httpd.conf
	cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.bak
	echo "IncludeOptional sites-enabled/*.conf" >> /etc/httpd/conf/httpd.conf
	cd /etc/httpd/sites-available
	echo "$1 www.$4 $4" >> /etc/hosts
	echo "127.0.0.1 $4" >> /etc/hosts
	echo "::1 $4" >> /etc/hosts
	echo "HOSTNAME=$4" >> /etc/sysconfig/network
	cat <<EOF > 010-$4.conf
<VirtualHost *:80>
    DocumentRoot /var/www/html/$4/
    Redirect / https://www.$4
</VirtualHost>

<VirtualHost *:443>
    DocumentRoot /var/www/html/$4/
    ServerName $4
    ServerAlias www.$4

    SSLEngine on
    SSLCertificateFile /etc/pki/tls/certs/kifarunix-demo.crt
    SSLCertificateKeyFile /etc/pki/tls/private/kifarunix-demo.key

    ErrorLog /var/www/html/$4/log/error.log
    CustomLog /var/www/html/$4/log/requests.log combined

    <Directory /var/www/html/$4/>
        Options +FollowSymlinks
        AllowOverride all
        Require all granted
    </Directory>
</VirtualHost>
EOF
	ln -s 010-$4.conf /etc/httpd/sites-enabled/
	setsebool -P httpd_unified 1
	mkdir /var/www/html/$4/log
	semanage fcontext -a -t httpd_log_t "/var/www/html/$4/log(/.*)?"
	restorecon -R -v /var/www/html/$4/log
	systemctl restart httpd
	systemctl enable iptables-service
	systemctl start iptables-service
	iptables -A INPUT -p tcp --dport 80 -m limit --limit 20/minute --limit-burst 100 -j ACCEPT
	echo 1 > /proc/sys/net/ipv4/ip_forward
	echo 1 > /proc/sys/net/ipv4/tcp_syncookies
	echo 0 > /proc/sys/net/ipv4/conf/all/accept_redirects
	echo 0 > /proc/sys/net/ipv4/conf/all/accept_source_route
	echo 1 > /proc/sys/net/ipv4/conf/all/rp_filter
	echo 1 > /proc/sys/net/ipv4/conf/lo/rp_filter
	echo 1 > /proc/sys/net/ipv4/conf/lo/arp_ignore
	echo 2 > /proc/sys/net/ipv4/conf/lo/arp_announce
	echo 1 > /proc/sys/net/ipv4/conf/all/arp_ignore
	echo 2 > /proc/sys/net/ipv4/conf/all/arp_announce
	echo 0 > /proc/sys/net/ipv4/icmp_echo_ignore_all
	echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts
	echo 30 > /proc/sys/net/ipv4/tcp_fin_timeout
	echo 1800 > /proc/sys/net/ipv4/tcp_keepalive_time
	echo 1 > /proc/sys/net/ipv4/tcp_window_scaling 
	echo 0 > /proc/sys/net/ipv4/tcp_sack
	echo 1280 > /proc/sys/net/ipv4/tcp_max_syn_backlog
	iptables -N block-scan
	iptables -A block-scan -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s -j RETURN
	iptables -A block-scan -j DROP
	badport="135,136,137,138,139,445"
	sudo iptables -A INPUT -p tcp -m multiport --dport $badport -j DROP
	sudo iptables -A INPUT -p udp -m multiport --dport $badport -j DROP
	service iptables save
	$SHELL
else
	printf "Sie haben nicht alle erforderlichen Parameter angegeben!\n\n1. IP-Adresse f. Port 53:\n2. Allow-Query Adresse:\n3. Recursion: no/yes\n4. Forward Zonen Name:\n5. Forward Allow-update:\n6. Reverse Zonen Name:\n7. Reverse Allow-Update:\n8. DNS-Name:\n9. MySQL Benutzer:\n10. MySQL Passwort:\n11. MySQL Root Passwort:\n\n"
fi
