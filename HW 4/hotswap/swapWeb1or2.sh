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
    thisContainer="$1"
    if [ "$thisContainer" != "web1" ] && [ "$thisContainer" != "web2" ]
    then
        echo "swapContainers: Invalid parameter - $thisContainer"
        exit 1
    fi
    if [ "$thisContainer" == "web1" ]
    then
        otherContainer="web2"
        thisContainerImg=$WEB1_IMG
        swap_script="/bin/swap1.sh"
    else
        otherContainer="web1"
        thisContainerImg=$WEB2_IMG
        swap_script="/bin/swap2.sh"
    fi

    # Before we start the container, we just check to make sure no stray ones of it are still remaining
    killitif $thisContainer
    # But since web1 may be spawned as ecs189_web1_1 by docker-compose, it doesn't hurt to remove that as well
    dockerComposeName="ecs189_""$thisContainer""_1"
    killitif $dockerComposeName

    # Now start up a fresh copy of it
    docker run -d --name $thisContainer --network $NETWORK_NAME $thisContainerImg

    # Give it some time to start up
    sleep 5

    # And execute the swap script on the nginx container to do the actual swapping
    docker exec $NGINX_CONTAINER_NAME /bin/bash $swap_script

    # And finally clean up the other container
    killitif $otherContainer
}

# Start off by determining which web container to swap to
currentActiveVersion=$(getCurrentActiveVersion)

case "$1" in
    "web1" | "1")
        if [ "$currentActiveVersion" != "web1" ]
        then
            echo "Starting the swap to web1.";
        else
            echo "Seems like the current version already is web1."
            exit 0
        fi
        swapTo "web1"
        ;;
    "web2" | "2")
        if [ "$currentActiveVersion" != "web2" ]
        then
            echo "Starting the swap to web2.";
        else
            echo "Seems like the current version already is web2."
            exit 0
        fi
        swapTo "web2"
        ;;
    *) echo "Did not recognize that parameter. Enter web1 or web2.";;
esac
