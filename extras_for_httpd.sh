#!/bin/bash
#a progress bar function.
function progress(){
    echo -ne '#####                     (25%)\r'
    sleep .5
    echo -ne '#############             (50%)\r'
    sleep .5
    echo -ne '#######################   (75%)\r'
    sleep .5
    echo -ne '###################################(100%)\r'
    echo -ne '\n'
}

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
infile_domain_name=$(cat vhosts_ssl.conf | grep 'ServerName' |  awk '{print $2}' | head -1)
echo "Current domain name in the file is : $infile_domain_name"
echo 
read -e -p "Enter your domain to create custom vhosts_ssl.conf : " -i "cloudzone.today" new_domain_name

if [[ new_domain_name != infile_domain_name ]]; then
     sed -i -e "s/$infile_domain_name/$new_domain_name/g" vhosts_ssl.conf
    if [ $? -eq 0 ]; then
        echo "Vhost.conf if now ready for new domain: $new_domain_name."
    else
        echo "Some Problem occured in making vhosts_ssl"
        exit 1
    fi
fi

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
    read -e -p "Do you want to install new SSL [y/n]: " -i "n" openssl_yn
    if [[ openssl_yn == 'y' ]]; then
        echo "We are installation Openssl 1.1.1g which is updated during this script."
        sleep 3
        sudo yum group install "Development Tools" -y
        wget https://www.openssl.org/source/openssl-1.1.1g.tar.gz
        sudo tar -xzf openssl-1.1.1g.tar.gz
        cd openssl-1.1.1g/
        ./config
        make
        ake install
        mv /usr/bin/openssl /root/
        ln -s /usr/local/lib64/libssl.so.1.1 /usr/lib64/
        ln -s /usr/local/lib64/libcrypto.so.1.1 /usr/lib64/
        rm /usr/bin/openssl
        ln -s /usr/local/bin/openssl /usr/bin/openssl
        openssl version
        openssl version |  grep -qi "openssl 1.1.1g" && echo "Installation done" || echo "Some problem occured.."
        cd ..
    else 
        echo "Okay. Not updating openssl this time. you can do this manually.."
    fi
fi
if [ ! -f $FILE ]; then
   echo "Directory change failed." 
   exit 1
fi
yum install mod_ssl -y
systemctl is-active --quiet httpd && echo "Apache is running.........." || echo "Apache is NOT running..........."

read -e -p "Do you want to generate CSR [y/n]: " -i "n" yn
if [[ yn == 'y' ]]; then
    echo "Generating a private key to use with CSR Out command"
    openssl genrsa -out /etc/pki/tls/private/custome.key 4096
    ll /etc/pki/tls/private/custom.key
    echo "Private key file is required only for the first time when ca-crt is included"
    sudo openssl req -new -key /home/ec2-user/custom.key -out csr.pem
    ll /home/ec2-user/csr.pem
    echo "CSR is generated, you can copy the csr file and send to CA for certificate"
    exit 0
fi
#sudo openssl req -new -key private.key -out csr.pem
echo "Please upload your certificate copy in ec2-user home directory"
echo "We will update until you do this.."
read -t 5 -n 1 -s -r -p "Press any key to continue"

echo "Checking the availability of certificate files............"
progress
echo "------------------------------------------------------------"
[[ -f /home/ec2-user/cert_httpd/certificate.crt ]] && echo "Certificate is present" || echo "Certificate file missing or renamed in ec2-home"
[[ -f /home/ec2-user/ca_bundle.crt ]] && echo "CA Bundle is present" || echo "CA Bundle file missing or renamed in ec2-home"

if [[ -f /home/ec2-user/private.key ]]; then
        echo "Private file is present in ec2-home directory"
else
        echo "Private file missing or renamed"
        echo " It seems that you did not receive private file from CA. We can generate this for you.."
        read -e -p "Do you want to private key [y/n]: " -i "n" yn2
        if [[ yn2 == 'y' ]]; then
            openssl genrsa -out /home/ec2-user/private.key 4096
            ll /home/ec2-user/private.key
            echo "Private key file is required only for the first time when ca-crt is included"
        fi
fi
echo "------------------------------------------------------------"
echo " "
echo "Copying files...................... "
\cp /home/ec2-user/certificate.crt /etc/pki/tls/certs/ && echo "Certificate Copy done............." || exit 0
\cp /home/ec2-user/ca_bundle.crt /etc/pki/tls/certs/ && echo "CA Bundle Copy done..........." || exit 0
\cp /home/ec2-user/private.key /etc/pki/tls/private/ && echo "Key Copy done..........." || exit 0
echo "**************************************************"
#permission for keys.
echo "Permission Adjustment for certs"
echo "--------------[ Done 1 ]-------------------------"
sleep 2
sudo chown root:root /etc/pki/tls/certs/certificate.crt
sudo chmod 644 /etc/pki/tls/certs/certificate.crt
echo "--------------[ Done 2 ]-------------------------"
chown root:root /etc/pki/tls/private/private.key
chmod 644 /etc/pki/tls/private/private.key
echo "--------------[ Done 3 ]-------------------------"
sudo chown root:root /etc/pki/tls/certs/ca_bundle.crt
sudo chmod 644 /etc/pki/tls/certs/ca_bundle.crt
echo "--------------[ Done 4 ]-------------------------"
echo " "
echo "List the certificates"
ls -al /etc/pki/tls/certs/certificate.crt
ls -al /etc/pki/tls/certs/ca_bundle.crt
ls -al /etc/pki/tls/private/private.key
echo "-----------------------------------------------------------------"
echo "Permission Adjustment done successfully"
echo "------------------------------------------------------------------"
echo "Transferring vhosts_ssl.conf from the local dir to /etc/httpd/conf.d "
if [[ -f '/etc/httpd/conf.d/vhost_ssl.conf' ]]; then
    \mv /etc/httpd/conf.d/vhosts_ssl.conf /etc/httpd/conf.d/vhost_$now.bk && echo "vhosts_ssl.conf renamed " || echo "vhost.conf Rename failed"
fi
if [[ -f '/etc/httpd/conf.d/vhost.conf' ]]; then
    \mv /etc/httpd/conf.d/vhosts.conf /etc/httpd/conf.d/vhost_$now.bk && echo "vhosts.conf renamed " || echo "vhost Rename failed"
fi
\cp vhosts_ssl.conf /etc/httpd/conf.d/ && echo "vhosts.conf copied " || echo "vhosts.conf copy failed"
echo ""

if [[ -f '/etc/httpd/conf.d/ssl.conf' ]]; then
    \mv /etc/httpd/conf.d/ssl.conf /etc/httpd/conf.d/ssl_$now.bk && echo "ssl.conf renamed " || echo "ssl.conf Rename failed"
fi
echo "****************************************************************"
echo "Creating dhparams.pem file, This will take some time."
echo "****************************************************************"
echo " "
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
