#!/usr/bin/expect -f
# set your variables here
echo "This script just creates a database and show on the command prompt."
if [ $USER != "root" ]; then
        echo "Script must be run as user sudo or root "
        exit 1
fi
#we are generating databasename and username from /dev/urandom command. 
dbname=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 8 ; echo '');

#we are generating username from openssl command
dbuser=$(openssl rand -base64 12 | tr -dc A-Za-z | head -c 8 ; echo '')

#Openssl is another way to generating 64 characters long password)
#dbpass=$(openssl rand -hex 8); #It generates max 16 digits password we can also use this for all above process.

dbpass=$(openssl rand -base64 8);

MYSQL_PASS=$(openssl rand -base64 12); #this is root password of mysql of 12 characters long.

#webroot="/var/www/html"
yum install expect -y

systemctl restart mariadb
systemctl enable mariadb

expect -f - <<-EOF
  set timeout 1
  spawn mysql_secure_installation
  expect "Enter current password for root (enter for none):"
  send -- "\r"
  expect "Set root password?"
  send -- "y\r"
  expect "New password:"
  send -- "${MYSQL_PASS}\r"
  expect "Re-enter new password:"
  send -- "${MYSQL_PASS}\r"
  expect "Remove anonymous users?"
  send -- "y\r"
  expect "Disallow root login remotely?"
  send -- "y\r"
  expect "Remove test database and access to it?"
  send -- "y\r"
  expect "Reload privilege tables now?"
  send -- "y\r"
  expect eof
EOF
echo "------------------------DB setup done-----------------------------------"
Q1="CREATE DATABASE IF NOT EXISTS $dbname;"
Q2="GRANT USAGE ON *.* TO $dbuser@localhost IDENTIFIED BY '$dbpass';"
Q3="GRANT ALL PRIVILEGES ON $dbname.* TO $dbuser@localhost;"
Q4="FLUSH PRIVILEGES;"
Q5="SHOW DATABASES;"  
SQL="${Q1}${Q2}${Q3}${Q4}${Q5}"
clear  
mysql -uroot -p$MYSQL_PASS -e "$SQL" && echo "DB Creation done" || echo "DB Creation failed"
echo "----------------Database processing done successfully-------------------"
echo "::::::Date_Time:::::::" $(date +%F_%R) 
echo "MySQL Root Password.." $MYSQL_PASS