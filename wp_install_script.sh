#!/usr/bin/expect -f

clear
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
#colour full text below.
#echo  -e "\033[33;5;7mTitle of the Program\033[0m"
#echo  -e "\033[5mTitle of the Program\033[0m"
#echo -e "\e[1;31m This is red text \e[0m"
#echo -e "\e[1;32m This is green text \e[0m"

# set your variables here
webroot_user=apache #for permission
webroot_group=apache
if [ $USER != "root" ]; then
        echo "Script must be run as user sudo or root "
        exit 1
fi
echo "**********************************************"
echo  -e "\033[33;5;7mWelcome to Automated installation of Wordpress\033[0m"
echo "**********************************************"
echo "Date and Time:" $(date +%F_%R)
echo "Sever Uptime is:" && uptime
sleep 3
echo "----------------------------------------------"
echo "Amazon Linux Information section"
echo "----------------------------------------------"
cat /etc/system-release
echo " "
curl http://169.254.169.254/latest/meta-data/public-hostname
echo " "
curl http://169.254.169.254/latest/meta-data/public-ipv4
echo " "
curl http://169.254.169.254/latest/meta-data/ami-id
echo " "
echo "----------------------------------------------"

if [ $? -eq 0 ]; then
    echo -e "\e[1;32m Great Let's Begin. \e[0m"
else
    echo "Not found [Amazon Linux OS]"
    exit 1
fi

read -t 3 -n 1 -s -r -p "Press any key to continue"
echo " "
echo "This Script install Wordpress automatically by creating a new database."
echo "This script assumes that Mysql 5.6 db on Amazon Linux2."
echo ""
mysql_ver="$(mysql --version|awk '{ print $5 }'|awk -F\, '{ print $1 }')"
echo "MySQL Version is : $mysql_ver"
echo  "------------------------------------------------"

if [[ `ps -acx|grep httpd|wc -l` > 0 ]]; then
    echo "Server Configured with Apache"
    httpd -v && echo "Apache OK" || exit 1
    echo "Suggested Server Name:"
    grep 'ServerName' /etc/httpd/conf/httpd.conf | awk '{ print $2}' | cut -d ':' -f 1
    echo "Suggested Webroot is below: "
    grep 'DocumentRoot ' /etc/httpd/conf/httpd.conf | awk  '{print $1}'
    read -e -p "Enter Your Webroot if not default :" -i "/var/www/html" webroot
    echo "Webroot Selected is: $webroot"
    sleep 3
    web_service=httpd
    systemctl is-active --quiet $web_service && echo "Apache is running" || echo "Apache is NOT running"
fi
if [[ `ps -acx|grep nginx|wc -l` > 0 ]]; then
    echo "Server is Configured with Nginx"
    nginx -v && echo "Nginx OK" || exit 1
    echo "Suggested Server Name:"
    grep 'server_name ' /etc/nginx/nginx.conf
    echo "Suggested Webroot is below: "
    grep 'root' /etc/nginx/nginx.conf
    read -e -p "Enter Your Webroot if not default :" -i "/usr/share/nginx/html" webroot
    echo "Webroot Selected is: $webroot"
    sleep 3
    web_service=nginx
    systemctl is-active --quiet $web_service && echo "Nginx is running" || echo "Nginx is NOT running"
fi

#read -e -p "Enter Your Name:" -i "Ricardo" NAME
#read -t 5 -n 1 -s -r -p "Press any key to continue"
#command && echo "OK" || echo "NOK"
echo "Let's check the PHP Status..."
systemctl is-active --quiet php-fpm && echo "PHP is running" || echo "PHP is NOT running"
php -v
sleep 5
echo " "
echo "Database Version Information "
mysql -V
sleep 1
echo "Going to Install some necessary tools"
progress
sleep 2
yum -y install net-tools wget zip unzip curl git pv ed expect
clear
echo "Installation of Tools-- done"
echo "---------------------------------------------------"
echo "Running service  information"
echo "***************************************************"
chkconfig --list
echo "Port Information"
echo "==================================================="
netstat -tulnp | grep $web_service
progress
clear
echo "---------------------------------------------------"

echo  -e "\033[5mMySQL Information & Prompt Action\033[0m"
echo "----------------------------------------------------"
read -e -p "Hey! Do you want me to create a new database for you [y/n] :" -i "n" create_db_yes_no
if [[ create_db_yes_no != "y" ]]; then
    echo "Okay, You seem to be with your own RDS database...."
    echo "Enter the database information to use with Wordpress"
    echo "----------------------------------------------------"
    read -p "Enter your database host or endpoint: " dbhost
    [ -z "$dbhost" ] && echo "Empty Input" 
    read -p "Enter your database name: " dbname
    [ -z "$dbname" ] && echo "Empty Input" 
    read -p "Enter your database username: " dbuser
    [ -z "$dbuser" ] && echo "Empty Input" 
    read -p "Enter your database password: " -s dbpass
    [ -z "$dbpass" ] && echo "Empty Input" 
    echo "Thank you..Please wait checking your credentials..."
    progress
    mysqladmin processlist -h $dbhost -P 3306 -u$dbuser -p$dbpass version | head -5
    echo "Value in db passwd:$dbpass"
    if [ $? -eq 0 ]; then
        echo -e "\e[1;32mGood news. Database credentials are perfect... \e[0m"
    else
        echo -e "\e[1;31mDatabase credentials failed..Not able to login. \e[0m"
            exit 1
    fi
else
    echo "This is automated db creation on local mysql server"
    echo "==================================================="
    echo "This only works if you mysql-server is hosted on the same server"
    echo "We understood. you want me to create a db for you on MySQL or Mariadb.."
    read -p "Enter your root or super user password :  " -s MYSQL_PASS
    echo "Thank you...Let me check your root passwrod.. Please wait.."
    sleep 3
    mysql -u root -p$MYSQL_PASS -e"exit"
    if [ $? -eq 0 ]; then
        echo "Mysql-root password is correct... Logging in.."
        mysqladmin -u root -p$MYSQL_PASS ping
        mysqladmin -u root -p$MYSQL_PASS version
        mysqladmin -u root -p$MYSQL_PASS status
        #we are generating databasename and username from /dev/urandom command. 
        dbname=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 8 ; echo '');
        #we are generating username from openssl command
        dbuser=$(openssl rand -base64 12 | tr -dc A-Za-z | head -c 8 ; echo '')
        #Openssl is another way to generating 64 characters long password)
        #dbpass=$(openssl rand -hex 8); #It generates max 16 digits password we can also use this for all above process.
        dbpass=$(openssl rand -base64 12 | tr -dc A-Za-z | head -c 12 ; echo '')
        dbhost="localhost"
        if [ $? -eq 0 ]; then
            progress
            echo "Wordpress DB credenetials successfully."
        else
            echo "Wordpress DB credentials generation failed"
            exit 1
        fi
        echo sleep 2
        echo "------------------------DB setup started-----------------------------------"
        Q1="CREATE DATABASE IF NOT EXISTS $dbname;"
        Q2="GRANT USAGE ON *.* TO $dbuser@localhost IDENTIFIED BY '$dbpass';"
        Q3="GRANT ALL PRIVILEGES ON $dbname.* TO $dbuser@localhost;"
        Q4="FLUSH PRIVILEGES;"
        Q5="SHOW DATABASES;"	
        SQL="${Q1}${Q2}${Q3}${Q4}${Q5}"
        mysql -uroot -p$MYSQL_PASS -e "$SQL" && echo "DB Creation done" || echo "DB Creation failed"
        sleep 1
    else
        echo "Please check your msyql-root credentials"
        sleep 2
        exit 1
    fi
fi

echo "Checking Webroot Folder .. please wait.."
progress

cd $webroot
if [ -z "$(ls -A $webroot)" ]; then
   echo "$webroot is Empty"
else
   echo "There are some files in the $webroot"
   echo "Zipping old files with lastbackup.zip, this can be found in webroot directory"
   cd $webroot
#  rm -rf lastbackup.zip
   zip -q lastbackup.zip $webroot/* .*
   mv -f lastbackup.zip ../
#  rm -rfv !{"lastbackup.zip"}
   rm -rf .*
   rm -rf *
fi
sleep 1
curl -O https://wordpress.org/latest.tar.gz
echo "Downloading ....................................."
echo "      "
tar -xf latest.tar.gz
#pv latest.tar.gz | tar xzf - -C .
cd wordpress
cp -rf . ..
cd ..
git clone https://github.com/ajaykumar011/wordpress-config.git
cp wordpress-config/wp-config.php .
cp wordpress-config/salt.sh .
chmod +x salt.sh
rm -rf wordpress-config
rm -R wordpress
echo "------------------------------------------"
echo "Here is the details of databse we got from above. "
echo "------------------------------------------"
echo "DB Name: $dbname"
echo "DB User: $dbuser"
echo "DB Password : $dbpass"
echo "Host Name : $dbhost"
echo "------------------------------------------"
echo " "
echo "Entering the information in wp-config file.. please wait."
progress
perl -pi -e "s/database_name_here/$dbname/g" wp-config.php
perl -pi -e "s/username_here/$dbuser/g" wp-config.php
perl -pi -e "s/password_here/$dbpass/g" wp-config.php
if [[ $dbhost != "localhost" ]]; then
perl -pi -e "s/localhost/$host/g" wp-config.php
fi
#Salt configuration section
sh salt.sh
rm -rf salt.sh
if [ $? -eq 0 ]; then
    echo "Salt information is feeded into wpconfig."
else
    echo "SALT Keys are not feeded. please do this manually"
fi
sleep 1

echo "<?php phpinfo();?>" > $webroot/info.php
echo "We are implementing the permission webroot folder: $webroot"
webroot_dir=$(dirname $webroot)

sudo chown -R $webroot_user:$webroot_group $webroot_dir
sudo chmod 2775 $webroot_dir
sudo find $webroot_dir -type d -exec chmod 2775 {} \;
sudo find $webroot_dir -type f -exec chmod 0664 {} \;
if [ $? -eq 0 ]; then
    echo "Permission set successfully."
else
    echo "Permisson could not set.. Skipping"
fi
sleep 1
clear
if [ $? -eq 0 ]; then
    echo "Wordpress DB configuration done successfully."
else
    echo "Wordpress DB configuration failed"
fi
wp_ver="$(grep wp_version wp-includes/version.php | awk -F "'" '{print $2}')"
echo "Your WP Version is $wp_ver"

rm latest.tar.gz
echo "******************************************************"
grep -qi 'Wordpress' $webroot/index.php && echo "Wordpress installed" || echo "Some problem"
echo "******************************************************"
echo Server Information
echo "******************************************************"
curl -I localhost
echo "=========================================================="
echo  -e "\033[5mInstallation is finished\033[0m"
echo -e "\e[1;32m Great Work.. \e[0m"
echo "=========================================================="
echo "$(tput setaf 7)$(tput setab 6)---|-WP READY TO ROCK-|---$(tput sgr 0)"
read -e -p "Do you want to implement SSL with the site [y/n]: " -i "y" yn
if [[ yn == 'y' ]]; then
    echo "Let me check your server configuraiton.."
    progress
    DIR=.git
    if [ $webroot == "httpd" ]; then
        echo "You are running apache: "
        if [ ! -d $DIR ]; then
        	echo "Your are not in correct directory. Directory check failed."
	        exit 1
        fi
        sh extras_for_httpd.sh
    elif [ $webroot == "httpd" ]; then
        echo "You are running Nginx: "
        if [ ! -d $DIR ]; then
        	echo "Your are not in correct directory. Directory check failed."
	        exit 1
        fi
        sh extras_for_nginx.sh
    else
        echo "Thank you.."
    fi
fi