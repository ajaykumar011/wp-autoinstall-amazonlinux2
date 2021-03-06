#!/usr/bin/expect -f

clear
#a progress bar function.
function progress(){
    echo -ne '##########                     (25%)\r'
    sleep .5
    echo -ne '##################             (50%)\r'
    sleep .5
    echo -ne '#################################   (75%)\r'
    sleep .5
    echo -ne '##################################################(100%)\r'
    echo -ne '\n'
}
function space(){                            
        for ((i=0;i<=$1;i++)); do            
                echo "  "                    
        done                                 
}                                            
                                        
function red(){                              
echo -e "\e[1;31m$1\e[0m"                  
}                                            
                                             
function green(){                            
echo -e "\e[1;32m$1\e[0m"                    
}                                            
                                                                            
#colour full text below.
#echo  -e "\033[33;5;7mTitle of the Program in Yellow\033[0m"
#echo -e "\e[1;31m This is red text \e[0m"
#echo -e "\e[1;32m This is green text \e[0m"
#echo  -e "\e[42mTitle of the Program in Green\033[0m"
#echo  -e "\e[41mTitle of the Program in Red\033[0m"
#echo  -e "\e[45mTitle of the Program in Magenta\033[0m"


#To Reset colors : echo -e "\e[0mNormal Text"

# set your variables here
readonly webroot_user=apache #for permission
readonly webroot_group=apache
readonly webroot=/var/www/html

script_dir=$(pwd)
if [ $USER != "root" ]; then
        echo "Script must be run as user sudo or root "
        exit 1
fi
echo "**********************************************"
echo  -e "\033[33;5;7mWelcome to Automated installation of Wordpress\033[0m"
echo "**********************************************"
echo "Date and Time:" $(date +%F_%R)
echo "Sever Uptime is:" && uptime
echo "Timezone adjustment to IST"
sudo ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
date
progress
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
    echo -e "\e[1;32mGreat Let's Begin. \e[0m"
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
    grep 'DocumentRoot ' /etc/httpd/conf/httpd.conf | awk  '{print $2}'
    #read -e -p "Enter Your Webroot if not default :" -i "/var/www/html" webroot
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
echo "-----------------------------------------------------------------"
systemctl is-active --quiet php-fpm && echo "PHP is running" || echo "PHP is NOT running"
php -v
echo "-----------------------------------------------------------------"
progress
echo " "
echo "Database Version Information "
mysql -V
echo "-----------------------------------------------------------------"
sleep 1
echo "Going to Install some necessary tools"
progress
sleep 2
yum -y install net-tools wget zip unzip curl git pv ed expect

echo "Installation of Tools-- done"
echo "------------------------------------------------------------------"
echo "Running service  information"
echo "******************************************************************"
chkconfig --list
space 2
echo "Port Information"
echo "==================================================="
netstat -tulnp 
sleep 3
echo "---------------------------------------------------"

echo  -e "\033[5mMySQL Information & Prompt Action\033[0m"
echo "----------------------------------------------------"
read -e -p "Hey! Do you want me to create a new database for you [y/n] :" -i "n" create_db_yes_no
if [[ create_db_yes_no != "y" ]]; then
    echo "Okay, You seem to be with your own RDS database...."
    echo "  "
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
    echo "  "
    echo "  "
    echo "Here is the details of databse we got from your inputs. "
    echo "------------------------------------------"
    echo "DB Name: $dbname"
    echo "DB User: $dbuser"
    echo "DB Password: ***********"
    echo "Host Name : $dbhost"
    echo "------------------------------------------"
    echo " "
    echo "Thank you..Please wait checking your credentials..."
    progress
    mysqladmin processlist -h$dbhost -P 3306 -u$dbuser -p$dbpass
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
space 3
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
echo "DB Password: $dbpass"
echo "Host Name: $dbhost"
echo "------------------------------------------"
echo " "
echo "Entering the information in wp-config file.. please wait."
progress
perl -pi -e "s/database_name_here/$dbname/g" wp-config.php
perl -pi -e "s/username_here/$dbuser/g" wp-config.php
perl -pi -e "s/password_here/$dbpass/g" wp-config.php
if [[ $dbhost != "localhost" ]]; then
perl -pi -e "s/localhost/$dbhost/g" wp-config.php
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
if [[ -f '/etc/httpd/conf.d/vhosts_ssl.conf' ]]; then
    \mv /etc/httpd/conf.d/vhosts_ssl.conf /etc/httpd/conf.d/vhost_$now.bk && echo "vhosts_ssl.conf renamed " || echo "vhost.conf Rename failed"
fi
if [[ -f '/etc/httpd/conf.d/vhost.conf' ]]; then
    \mv /etc/httpd/conf.d/vhosts.conf /etc/httpd/conf.d/vhost_$now.bk && echo "vhosts.conf renamed " || echo "vhost Rename failed"
fi
if [[ -f '/etc/httpd/conf.d/ssl.conf' ]]; then
    \mv /etc/httpd/conf.d/ssl.conf /etc/httpd/conf.d/ssl_$now.bk && echo "ssl.conf renamed " || echo "ssl.conf Rename failed"
fi
progress

\cp $script_dir/vhosts.conf /etc/httpd/conf.d/ && echo "vhosts.conf copied " || echo "vhosts.conf copy failed"
echo " "

echo "Confiiguring your non-ssl Vhost file which is to be copied to conf.d"
infile_domain_name=$(cat $script_dir/vhosts.conf | grep 'ServerName' |  awk '{print $2}' | head -1)
echo "Current domain name in the file is : $infile_domain_name"
space 2
read -e -p "Enter your domain to create custom vhosts.conf : " -i "cloudzone.today" new_domain_name

if [[ new_domain_name != infile_domain_name ]]; then
     sed -i -e "s/$infile_domain_name/$new_domain_name/g" $script_dir/vhosts.conf
    if [ $? -eq 0 ]; then
        echo "Vhost.conf if now ready for new domain: $new_domain_name."
    else
        red "Some Problem occured in making vhosts file"
        exit 1
    fi
fi

echo "creating .htacces file for you.. Please wait"
progress
echo "copying .htaccess file to the web-directory"
\mv $webroot/.htaccess $webroot/.htacces_last_conf
\cp $script_dir/.htaccess $webroot/
sed -i "s/yoursite.com/$new_domain_name/g" $webroot/.htaccess
chown -R $webroot_user:$webroot_group $webroot/.htaccess
chmod -R 644 $webroot/.htaccess

echo " "
echo "We are implementing the permission webroot folder: $webroot"
progress
echo webroot value is : $webroot
sleep 3
webroot_dir=$(dirname $webroot)

sudo chown -R $webroot_user:$webroot_group $webroot_dir
sudo chmod -R 2775 $webroot_dir
sudo find $webroot_dir -type d -exec chmod 2775 {} \;
sudo find $webroot_dir -type f -exec chmod 0664 {} \;
if [ $? -eq 0 ]; then
    echo " "
    green "Permission set successfully."
else
    echo " "
    red "Permisson could not set.. Skipping"
fi

wp_ver="$(grep wp_version wp-includes/version.php | awk -F "'" '{print $2}')"
if [ $? -eq 0 ]; then
    green "Wordpress DB configuration done successfully."
else
    red "Wordpress DB configuration failed"
fi
echo "Your WP Version is $wp_ver"

rm latest.tar.gz
echo "******************************************************"
grep -qi 'Wordpress' $webroot/index.php && echo "Wordpress files are copied to webfolder" || echo "Some problem with the Installation"
echo "******************************************************"
space 1
echo -e "\033[5mInstallation is finished but not confirmed the site is accessible..\033[0m"
echo -e "\e[1;32mGreat Work.. \e[0m"
echo "=========================================================="
echo "$(tput setaf 7)$(tput setab 6)---|-WP READY TO ROCK-|---$(tput sgr 0)"

access_log_file=$(cat /etc/httpd/conf.d/vhosts.conf | grep -i CustomLog | awk '{print $2}')
error_log_file=$(cat /etc/httpd/conf.d/vhosts.conf | grep -i ErrorLog | awk '{print $2}')
log_dir=$(dirname $access_log_file)

chown -R $webroot_user:root $log_dir
chmod -R 775 $log_dir

space 2
progress
systemctl restart httpd && green "Apache OK" || red "Apache is not working. Some problem"
progress
systemctl restart httpd && green "PHP OK" || red "Php-fpm is not working.. Some problme"
progress
curl -I www.$new_domain_name | grep -E '301|200'
if [ $? -eq 0 ]; then
    green "******************************************************************************"
    echo  -e "\e[42mWORDPRESS IS INSTALLED AND SITE IS READY TO USE. GREAT WORK.. \033[0m"
    green "******************************************************************************"
    space 3
else 
    echo  -e "\e[41mThere are still some problem with the Site.. Try browsing\033[0m"
fi

curl -I www.$new_domain_name 
curl -I $new_domain_name 
space 3

read -p "Do you want to implement onw SSL with the site [y/n]: " q
echo "value of yn is : $q"
if [[ $q == "y" ]]; then
    echo "Let me check your server configuraiton.."
    progress
    if [ $webroot == "httpd" ]; then
        echo "You are running apache: "
        echo "you can run the script [sh extras_for_httpd.sh] after exiting this program"
        progess
        sh extras_for_httpd.sh
    elif [ $webroot == "nginx" ]; then
        echo "You are running Nginx: "
        echo "you can run the script [sh extras_for_nginx.sh] after exiting this program"
        progress
        sh extras_for_nginx.sh
    else
        echo "Something wrong in server selection"
    fi
else
    echo "Thank you and enjoy browsing the site"
    echo "If you see 200 OK it means your site is working fine"
    echo "Command is : curl -I localhost"
fi