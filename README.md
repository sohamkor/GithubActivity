# GitHub Activity Monitor and Docker Container Swapping
Project for ECS 189E.

by __Soham Koradia__ and __Kevin Ow__

Add a file named "README.SUBMISSION"  to the root directory, Explaining the files you have created, what they do, and the commands you will type in, to demonstrate the hotswap. 

# Initial Files/Images
### Docker Images
Initially we have three docker images created to work with; our activity_old image which is the image built off the old activity.war; 
our activity_new image which is the image that has our improved website and our ng image which is the image built from Professor Devanbu's nginx-rev directory.

### Java Files
Our java file GithubQuerier in src/main/querying/github gets the last 10 pull requests from a user.

 

# Commands We Will Execute

### Manual Swap
    1. This initializes both nginx and web1 (activity_old).  
    Command: ./dorun.sh

    2. This displays all the processes that are running so we can find the port # and display the website
    Command: docker ps -a
    
    3. This starts up the new container/web page that we're going to swap to from the image "activity_new" into the container "web2"
    Command: docker run --name web2 --network ecs189_default activity_new

    4. This will execute the swap from web1 to web2
    Command: docker exec ecs189_proxy_1 /bin/bash /bin/swap2.sh

    5. This removes the old container that's running
    docker rm -f ecs189_web1_1
    
    6. Now we are done swapping from 1 -> 2
    
    7. To swap back from 2 -> 1 start with this command which starts up the old container from "activity_old" into the container "web1"
    Command: docker run --name web1 --network ecs189_default activity_old
    
    8. Now we'll run the script which swaps us from web2 -> web1
    Command: docker exec ecs_189_proxy_1 /bin/bash /bin/swap1.sh
    
    9. Now clean up the old container that we swapped from (web2)
    Command: docker rm -f web2
    

