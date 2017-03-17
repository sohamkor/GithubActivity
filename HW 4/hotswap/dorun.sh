#/bin/bash

function killitif {
    docker ps -a  > /tmp/yy_xx$$
    if grep --quiet $1 /tmp/yy_xx$$
     then
     echo "killing older version of $1"
     docker rm -f `docker ps -a | grep $1  | sed -e 's: .*$::'`
   fi
}


# Remove any existing containers, so we don't have failure
# on the run command because of existing named containers. 

killitif proxy
killitif web1
killitif web2

# Start the compose yml thing up, but using the network name ecs189
# This is so that the other shells know where to find the containers
# to hotswap, regardless of the directories 

docker-compose -p ecs189 up  & 

# Initially the reverse proxy points at engineering URL 
# WE first make it point at the right url, using the init.sh script

sleep 10 && docker exec ecs189_proxy_1 /bin/bash /bin/init.sh
echo "redirecting to the service" 
echo "...nginx restarted, should be ready to go!" 


