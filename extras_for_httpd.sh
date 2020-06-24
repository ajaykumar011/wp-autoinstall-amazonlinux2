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
#Open SSL Installation section.
openssl version |  grep -qi "openssl 1.1.1g"
if [ $? -eq 0 ]; then
    echo "Open SSL Seems to be updated."
else
    echo "Open SSL outdate.. Needs to update. please wait"
    echo "We are installation Openssl 1.1.1g which is updated during this script."
    sleep 3
    sudo yum group install "Development Tools" -y
    wget https://www.openssl.org/source/openssl-1.1.1g.tar.gz
    sudo tar -xzf openssl-1.1.1g.tar.gz
    cd openssl-1.1.1g/
    ./config
    make
    make install
    mv /usr/bin/openssl /root/
    ln -s /usr/local/lib64/libssl.so.1.1 /usr/lib64/
    ln -s /usr/local/lib64/libcrypto.so.1.1 /usr/lib64/
    rm /usr/bin/openssl
    ln -s /usr/local/bin/openssl /usr/bin/openssl
    openssl version
    openssl version |  grep -qi "openssl 1.1.1g" && echo "Installation done" || echo "Some problem occured.."
    cd ..
fi
if [ ! -f $FILE ]; then
   echo "Directory change failed." 
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
echo ""
chown root:root /etc/pki/tls/private/custom.key
chmod 644 /etc/pki/tls/private/custom.key
echo ""
echo "List the certificates"
ls -al /etc/pki/tls/certs/certificate.crt
ls -al /etc/pki/tls/private/custom.key
echo ""
echo "Permission Adjustment done successfully"
echo ""
echo "Transferring httpd.conf and from git "
if [[ -f '/etc/httpd/conf.d/vhost.conf' ]]; then
\mv /etc/httpd/conf.d/vhost.conf /etc/httpd/conf.d/vhost_$now.bk
fi
echo "Copying vhosts.conf custom file from git."
\cp vhosts.conf /etc/httpd/conf.d/
#\cp gzip.conf /etc/httpd/conf/
echo ""
echo "Creating dhparams.pem file, This will take some time."
echo ""
sleep 2
if [[ ! -f '/etc/pki/tls/certs/dhparams.pem' ]]; then
openssl dhparam -out /etc/pki/tls/certs/dhparams.pem 2048
fi
echo ""
echo "Copying ssl_httpd.conf file to /etc/httpd/conf.d directory"
if [[ ! -d '/etc/httpd/conf/snippets' ]]; then
mkdir -p /etc/httpd/conf/snippets
fi
echo "ssl_httpd.conf file copying process"
echo ""
\cp ssl_httpd.conf /etc/httpd/conf/snippets && echo "ssl_httpd.conf copied" || echo "ssl_httpd.conf copy error"

httpd -t  && echo "Apache Configuration is Okay" || echo "Some Problem in Apache config"
echo ""
service httpd restart

echo "******************************************************"
echo Certificate Information
echo "******************************************************"
curl --insecure -v https://localhost 2>&1 | awk 'BEGIN { cert=0 } /^\* Server certificate:/ { cert=1 } /^\*/  { if (cert) print }'
