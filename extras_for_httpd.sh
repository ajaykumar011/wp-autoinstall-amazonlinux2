#!/bin/bash
now=$(date +"%m_%d_%Y")
echo "**********************************************"
echo "Welcome to Automated SSL on Nginx"
echo "**********************************************"
read -e -p "Enter Your Webroot if not default :" -i "/var/www/html" webroot
if [[ $webroot != "/var/www/html" ]]
	echo "This script only work with default config of nginx"
	exit 1
fi	
if [ $USER != "root" ]; then
        echo "Script must be run as user sudo or root "
        exit 1
fi
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

echo "Transferring nginx.conf and gzip.conf from git "
mv /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf_$now.bk

\cp vhosts.conf /etc/httpd/conf.d/
#\cp gzip.conf /etc/httpd/conf/
#chomod –R 775 /var/log/nginx 

echo "creating dhparams.pem file"
sleep 2
sudo openssl dhparam -out /etc/pki/tls/certs/dhparams.pem 2048

echo "Copying ssl.conf file to /etc/nginx/snippets directory"
sudo mkdir -p /etc/httpd/conf.d/
\cp ssl.conf /etc/nginx/conf.d/

nginx -t 
if [ $? -eq 0 ]; then
    echo "Something happend Wrong."
else
    echo "SSL seems to be implemented..]"
     exit 1
fi
service nginx restart

echo "******************************************************"
echo Certificate Information
echo "******************************************************"
curl --insecure -v https://localhost 2>&1 | awk 'BEGIN { cert=0 } /^\* Server certificate:/ { cert=1 } /^\*/  { if (cert) print }'