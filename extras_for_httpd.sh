#!/bin/bash
now=$(date +"%m_%d_%Y")
FILE=awsinfo.php
DIR=.git
if [ $USER != "root" ]; then
        echo "Script must be run as user sudo or root "
        exit 1
fi

if [ ! -f $FILE ]; then
   echo "Your are not in correct directory. File check failed." 
   exit 1
fi
if [ ! -d $DIR ]; then
	echo "Your are not in correct directory. Directory check failed."
	exit 1
fi
echo "**********************************************"
echo "Welcome to Automated SSL on Apache"
echo "**********************************************"
echo "This Script works only with default installation location of Apache"
#read -t 5 -n 1 -s -r -p "Press any key to continue"
webroot=/var/www/html
echo "Webroot is : $webroot"
if [[ $webroot != "/var/www/html" ]]; then
	echo "This script only work with default config of Apache"
	exit 1
fi	
yum install mod_ssl -y
systemctl is-active --quiet httpd && echo "Apache is running" || echo "Apache is NOT running"
echo "Genrating custom.key private key file"
openssl genrsa -out custom.key 4096
#sudo openssl req -new -key custom.key -out csr.pem
echo "Transferring certificate.crt from git and custom.key from local to cert directory"
sleep 2
\cp certificate.crt /etc/pki/tls/certs/
\cp custom.key /etc/pki/tls/private/

#permission for keys.
echo "Permission Adjustment for certs"
sleep 2
sudo chown root:root /etc/pki/tls/certs/certificate.crt
sudo chmod 644 /etc/pki/tls/certs/certificate.crt
ls -al /etc/pki/tls/certs/certificate.crt
chown root:root /etc/pki/tls/private/custom.key
chmod 644 /etc/pki/tls/private/custom.key
ls -al /etc/pki/tls/private/custom.key

echo "Transferring httpd.conf and gzip.conf from git "
if [[ -f '/etc/httpd/conf.d/vhost.conf' ]]; then
\mv /etc/httpd/conf.d/vhost.conf /etc/httpd/conf.d/vhost_$now.bk
fi

\cp vhosts.conf /etc/httpd/conf.d/
#\cp gzip.conf /etc/httpd/conf/

echo "creating dhparams.pem file"
sleep 2
openssl dhparam -out /etc/pki/tls/certs/dhparams.pem 2048

echo "Copying ssl_httpd.conf file to /etc/httpd/conf.d directory"
if [[ ! -d '/etc/httpd/conf/snippets' ]]; then
mkdir -p /etc/httpd/conf/snippets
fi
\cp ssl_httpd.conf /etc/httpd/conf/snippets && echo "ssl_httpd.conf copied" || echo "ssl_httpd.conf copy error"

httpd -t  && echo "Apache Configuration is Okay" || echo "Some Problem in Apache config"
service httpd restart

echo "******************************************************"
echo Certificate Information
echo "******************************************************"
curl --insecure -v https://localhost 2>&1 | awk 'BEGIN { cert=0 } /^\* Server certificate:/ { cert=1 } /^\*/  { if (cert) print }'
