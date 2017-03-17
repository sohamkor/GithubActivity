#!/usr/bin/env bash

readonly NETWORK_NAME="ecs189_default"
readonly WEB1_IMG="activity_old"
readonly WEB2_IMG="activity_new"
readonly NGINX_CONTAINER_NAME="ecs189_proxy_1"

# ------------------- Helper Methods ------------------
# Really handy method taken from Prem's init.sh script
function killitif() {
    docker ps -a  > /tmp/yy_xx$$
    if grep --quiet $1 /tmp/yy_xx$$
     then
     echo "killing older version of $1"
     docker rm -f `docker ps -a | grep $1  | sed -e 's: .*$::'`
   fi
}

function getCurrentActiveVersion() {
    # Get the config file as it is right now from the nginx server
    currConfig=`docker exec ecs189_proxy_1 /bin/cat /etc/nginx/nginx.conf`

    # Extract the web number from it (can be either 1 or 2, atleast as far as current functionality goes)
    webVersion=`echo "$currConfig" | sed -n -e 's#proxy_pass http://web##p' | sed -e 's/ //g' | head -c 1`

    # Print this out
    echo "web$webVersion"
}

function swapTo() {
    #Container we swap to
    newContainer="$1"
    newImg="$2"
    if [ "$newContainer" != "web1" ] && [ "$newContainer" != "web2" ]
    then
        echo "swapContainers: Invalid parameter - $newContainer"
        exit 1
    fi
    if [ "$newContainer" == "web1" ]
    then
        oldContainer="web2"
        newContainerImg=$newImg
        swap_script="/bin/swap1.sh"
    else
        oldContainer="web1"
        newContainerImg=$newImg
        swap_script="/bin/swap2.sh"
    fi

    # Before we start the container, we just check to make sure no stray ones of it are still remaining
    killitif $newContainer
    # But since web1 may be spawned as ecs189_web1_1 by docker-compose, it doesn't hurt to remove that as well
    dockerComposeName="ecs189_""$newContainer""_1"
    killitif $dockerComposeName

    # Now start up a fresh copy of it
    docker run -d --name $newContainer --network $NETWORK_NAME $newContainerImg

    # Give it some time to start up
    sleep 5

    # And execute the swap script on the nginx container to do the actual swapping
    docker exec $NGINX_CONTAINER_NAME /bin/bash $swap_script

    # And finally clean up the other container
    killitif $oldContainer
}

# Start off by determining which web container to swap to
currentActiveVersion=$(getCurrentActiveVersion)

randomImg="$1"

if ["$currentActiveVersion" == "web1"]
    then
        echo "Starting the swap to $randomImg in container web2.";
        swapTo "web2" "$randomImg"
fi
if ["$currentActiveVersion" == "web2"]
    then
        echo "Starting the swap to $randomImg in container web1";
        swapTo "web1" "$randomImg"

fi
