#!/usr/bin/env bash
#/bin/bash
# This shell is to swap from web1 to web2
cd /etc/nginx
sed -e s?web1:8080/activity/?web2:8080/activity/? <nginx.conf > /tmp/xxx
cp /tmp/xxx nginx.conf
service nginx reload 
