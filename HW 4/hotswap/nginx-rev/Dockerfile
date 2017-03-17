############################################################
# Dockerfile to build Nginx Installed Containers
# Based on Ubuntu
############################################################

# Set the base image to Ubuntu
FROM ubuntu

# File Author / Maintainer
MAINTAINER Prem Devanbu & Vincent Hellendoorn

# Install Nginx

# Add application repository URL to the default sources
# RUN echo "deb http://archive.ubuntu.com/ubuntu/ raring main universe" >> /etc/apt/sources.list

# Update the repository
RUN apt-get update 
    

# Install necessary tools
RUN apt-get install -y nano wget dialog net-tools curl

# Download and Install Nginx
RUN apt-get install -y nginx  

# Remove the default Nginx configuration file
RUN rm -v /etc/nginx/nginx.conf

# Copy a configuration file from the current directory
ADD nginx.conf /etc/nginx/

# THese below are the shells we need inside the nginx container to do swapping

ADD init.sh /bin/init.sh
ADD swap1.sh /bin/swap1.sh
ADD swap2.sh /bin/swap2.sh

# Append "daemon off;" to the beginning of the configuration
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# Expose ports
EXPOSE 8888

# Set the default command to execute
# when creating a new container
CMD service nginx start
