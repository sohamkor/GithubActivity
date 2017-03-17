#/bin/bash
# This shell is inside the nginx docker, and used to start off operations. 
# IT's fired off by the dorun.sh to start things
cd /etc/nginx
sed -e s?www.cs.ucdavis.edu?web1:8080/activity/? <nginx.conf > /tmp/xxx
cp /tmp/xxx nginx.conf
service nginx reload 
