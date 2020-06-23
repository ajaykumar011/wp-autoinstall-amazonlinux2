
#!/bin/bash
#This script works with Amazon Linux 2. You need to first login as root via 'sudo -s' command. you also need to install git first.
#variables define here..

#sudo -s # login as root to execute these commands.
if [ $USER != "root" ]; then
        echo "Script must be run as user sudo or root "
        exit 1
fi

servername="$(hostname):80"
myip=$(curl -s http://myip.dnsomatic.com | grep -P '[\d.]')
#Installation begins here..
alias vi=vim
echo "Your Amazon AMI Version"
cat /etc/system-release
echo "Your OS Release information"
cat /etc/os-release
uname -a

yum -y groupinstall "Development Tools"
#yum -y mod_ssl openssl

#Amazon-linux-extras are packages like EPEL. We can enable upgraded version of php and mariadb here. We would install after that.
#amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2 
yum install -y mod_ssl openssl 
#yum -y install httpd php php-common php-mysql mariadb-server mariadb mod_ssl openssl

yum info httpd mariadb php   #let's get the repo version information

for r in httpd mariadb; do systemctl start $r; done  
for r in httpd mariadb; do systemctl status $r; done  
for r in httpd mariadb; do systemctl enable $r; done  

systemctl is-enabled httpd
systemctl is-enabled mariadb
yum search php-

#echo "<html><body><h1>Server ready </h1></body></html>" > /var/www/html/index.html 
#echo "<?php phpinfo(); ?>" > /var/www/html/phpinfo.php

#perl -pi -e "s/www.example.com:80/$servername/g" /etc/httpd/conf/httpd.conf
service httpd restart

sh dbcreatecawsph7.sh
# phpMyAdmin is a web-based database management tool that you can use to view and edit the MySQL databases on your EC2 instance"

yum install php-mbstring.x86_64 php-zip.x86_64 -y
service httpd restart
cd /var/www/html
wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz
mkdir phpMyAdmin && tar -xzf phpMyAdmin-latest-all-languages.tar.gz -C phpMyAdmin --strip-components 1
rm -rf phpMyAdmin-latest-all-languages.tar.
service mariadb restart
echo "your phpMyAdmin link is ready to use"
# you can browse the site from this link http://my.public.dns.amazonaws.com/phpMyAdmin

#perl -pi -e "s/127.0.0.1/$myip/g" /etc/httpd/conf.d/phpMyAdmin.conf
echo "phpMyadmin Installed... you can browser by using your servername/phpMyAdmin link."
echo " "
echo "Server [$servername] status....."
echo "================================================"
curl -I -L http://$servername
echo "Server WAN IP Address " $myip 
echo "Server Host name " $(hostname) 
echo "-----------------------------------------------------------" 
echo "Version Information of Installed LAMP"

httpd -v
#Server version: Apache/2.4.33 ()
php -v
#PHP 7.2.5 (cli) (built: May 29 2018 19:08:12) ( NTS )
mysql --version
#mysql  Ver 15.1 Distrib 10.2.10-MariaDB,
cat /etc/system-release
#Amazon Linux 2
echo "=========================================================="
echo "Linux AMI SERVER Setup and Wordpress Installation is completed."
echo "=========================================================="