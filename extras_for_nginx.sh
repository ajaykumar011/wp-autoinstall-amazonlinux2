#!/bin/bash
echo "**********************************************"
echo "Welcome to Automated SSL on Nginx"
echo "**********************************************"
read -e -p "Enter Your Webroot if not default :" -i "/usr/share/nginx/html" webroot
if [[ $webroot != "/usr/share/nginx/html" ]]
	echo "This script only work with default config of nginx"
	exit 1
fi	
if [ $USER != "root" ]; then
        echo "Script must be run as user sudo or root "
        exit 1
fi
systemctl is-active --quiet nginx && echo "Nginx is running" || echo "Nginx is NOT running"

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
mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.org
mv nginx.conf /etc/nginx/
\cp gzip.conf /etc/nginx/conf.d/
#chomod –R 775 /var/log/nginx 

echo "creating dhparams.pem file"
sleep 2
sudo openssl dhparam -out /etc/pki/tls/certs/dhparams.pem 2048

echo "Copying ssl.conf file to /etc/nginx/snippets directory"
sudo mkdir -p /etc/nginx/snippets
\cp ssl.conf /etc/nginx/snippets/

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