#!/bin/bash
echo "**********************************************"
echo "Welcome to Automated SSL on Nginx"
echo "**********************************************"
read -e -p "Enter Your Webroot if not default :" -i "/usr/share/nginx/html" webroot
if [[ $webroot != "/usr/share/nginx/html" ]]; then
	echo "This script only work with default config of nginx"
	exit 1
fi	
if [ $USER != "root" ]; then
        echo "Script must be run as user sudo or root "
        exit 1
fi
systemctl is-active --quiet nginx && echo "Nginx is running" || echo "Nginx is NOT running"

read -e -p "Do you want to generate CSR [y/n]" -i "n" yn
if [[ yn == 'y']]; then
    sudo openssl req -new -key custom.key -out csr.pem
    ll csr.pem
    echo "CSR is generated, you can copy the csr file and send to CA for certificate"
    exit 0
fi

read -e -p "Do you want to private key [y/n]" -i "n" yn2
if [[ yn2 == 'y']]; then
    openssl genrsa -out custom.key 4096
    ll custom.key
    echo "private key file is required only for the first time when ca-crt is included"
    exit 0
fi
echo "Transferring certificate.crt from git and custom.key from local to cert directory"
sleep 2

if [[ -f ./cert_nginx/certificate.crt ]] && echo "Certificate is present" || echo "Certificate file missing or renamed"
if [[ -f ./cert_nginx/private.key ]] && echo "Private file is present" || echo "Private file missing or renamed"

echo "Copying files.. "
\cp ./cert_nginx/certificate.crt /etc/pki/tls/certs/ && echo "Certificate Copy done" || exit 0
\cp ./cert_nginx/private.key /etc/pki/tls/private/ && echo " Key Copy done" || exit 0

#permission for keys.
echo "Permission Adjustment for certs"
sleep 2
sudo chown root:root /etc/pki/tls/certs/certificate.crt
sudo chmod 644 /etc/pki/tls/certs/certificate.crt
ls -al /etc/pki/tls/certs/certificate.crt
chown root:root /etc/pki/tls/private/private.key
chmod 644 /etc/pki/tls/private/private.key
ls -al /etc/pki/tls/private/private.key

echo "Transferring nginx.conf and gzip.conf from git "
mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.org
mv nginx.conf /etc/nginx/
\cp gzip.conf /etc/nginx/conf.d/
#chomod –R 775 /var/log/nginx 

if [[ ! -f '/etc/pki/tls/certs/dhparams.pem' ]]; then
openssl dhparam -out /etc/pki/tls/certs/dhparams.pem 2048
fi
echo ""
echo "Copying ssl_nginx.conf file to /etc/nginx/snippets directory"
sudo mkdir -p /etc/nginx/snippets
\cp ssl_nginx.conf /etc/nginx/snippets/

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