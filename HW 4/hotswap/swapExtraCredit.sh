#!/usr/bin/env bash

readonly NETWORK_NAME="ecs189_default"
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
    imgToUpdateTo="$1"
    thisContainer=$(getCurrentActiveVersion)
    if [ "$thisContainer" != "web1" ] && [ "$thisContainer" != "web2" ]
    then
        echo "swapContainers: Invalid parameter - $thisContainer"
        exit 1
    fi
    if [ "$thisContainer" == "web1" ]
    then
        otherContainer="web2"
        swap_script="/bin/swap2.sh"
    else
        otherContainer="web1"
        swap_script="/bin/swap1.sh"
    fi

    # Before we start the container, we just check to make sure no stray ones of it are still remaining
    killitif $otherContainer
    # But since web1 may be spawned as ecs189_web1_1 by docker-compose, it doesn't hurt to remove that as well
    dockerComposeName="ecs189_""$otherContainer""_1"
    killitif $dockerComposeName

    # Now start up a fresh copy of it
    docker run -d --name $otherContainer --network $NETWORK_NAME $imgToUpdateTo

    # Give it some time to start up
    sleep 5

    # And execute the swap script on the nginx container to do the actual swapping
    docker exec $NGINX_CONTAINER_NAME /bin/bash $swap_script

    # And finally clean up the other container
    killitif $thisContainer
}

function isValidImage() {
    imageName="$1"
    docker image list | cut -d " " -f 1 | grep --quiet -w "$imageName"
    return $?
}

# Make sure that the parameter given is a valid image
imageToSwapTo="$1"
if [ "$imageToSwapTo" == "" ]
then
    echo "Parameter missing: specify the image to swap to."
    exit 1
fi

if ! isValidImage $imageToSwapTo
then
    echo "The given image is not valid."
    exit 1
fi

# Now that we have determined that the given image is one that is valid and therefore be used to create a container
# that is what we'll do
swapTo $imageToSwapTo
echo "Swapped successfully."
