#!/bin/bash -e
webroot=httpd
read -p "Do you want to implement SSL with the site [y/n]: " q
echo "value of yn is : $q"
if [[ $q == "y" ]]; then
    echo "Let me check your server configuraiton.."
    progress
    if [ $webroot == "httpd" ]; then
        echo "You are running apache: "
        echo "you can run the script [sh extras_for_httpd.sh] after exiting this program"
        sleep 5
        sh extras_for_httpd.sh
    elif [ $webroot == "nginx" ]; then
        echo "You are running Nginx: "
        echo "you can run the script [sh extras_for_nginx.sh] after exiting this program"
        sleep 5
        sh extras_for_nginx.sh
    else
        echo "Something wrong in server selection"
    fi
fi