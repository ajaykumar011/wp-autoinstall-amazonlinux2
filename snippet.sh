#!/bin/bash -e
webroot=httpd
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