## HPCC-Docker Images and Simple Deployment

Reference https://hub.docker.com/r/hpccsystems/platform-ce/ for HPCC Docker images usage

## Prerequisites
Install [Docker](https://docs.docker.com/engine/installation/) and [Docker-compose](https://docs.docker.com/compose/install/)
Ensure your Docker machine is running. For example if you use Virtualbox, or Docker daemon on native Linux, verify that it is running.
## Deploy a HPCC Cluster with Docker Compose
The default Docker compose configuration file **docker-compose.yml** defines three services: hpcc-master, hpcc-roxie, and hpcc-thor. 
hpcc-master will host dali, esp, dfuserver, etc. 
The default HPCC image is for Ubuntu Trusty.
You can change to other supplied [docker hpcc images](https://hub.docker.com/r/hpccsystems/platform-ce/tags/) or build a new one yourself.

### Start HPCC cluster 
Download HPCC-Docker.git:
```sh
git clone https://github.com/xwang2713/HPCC-Docker.git
```
The default repository directory is **HPCC-Docker**
Go to the HPCC-Docker directory and run the following: 
```sh
docker-compose up -d
Creating hpccdocker_hpcc-roxie_1
Creating hpccdocker_hpcc-thor_1
Creating hpccdocker_hpcc-master_1
```
The default **docker-compose.yaml** defines one Thor slave and one Roxie instance.
To check the cluster status and verify the state for each container is "UP": 
```sh
docker-compose ps
          Name                        Command               State                          Ports                         
------------------------------------------------------------------------------------------------------------------------
hpccdocker_hpcc-master_1   bash -c cd /tmp; /tmp/run_ ...   Up      8002/tcp, 0.0.0.0:8010->8010/tcp, 8015/tcp, 9876/tcp 
hpccdocker_hpcc-roxie_1    bash -c sudo /usr/sbin/sshd -D   Up      8002/tcp, 8010/tcp, 8015/tcp, 9876/tcp               
hpccdocker_hpcc-thor_1     bash -c sudo /usr/sbin/sshd -D   Up      8002/tcp, 8010/tcp, 8015/tcp, 9876/tcp  
```
If you use VM as a host get the host ip address, otherwise the host ip can be localhost or actual ip address:
```sh
docker-machine ls
NAME      ACTIVE   DRIVER       STATE     URL                         SWARM   DOCKER   ERRORS
default   *        virtualbox   Running   tcp://192.168.99.100:2376           v1.9.1   

```
To verify and play with the HPCC Platform: http://\{host ip\}:8010. 
For example: 
 http://192.168.99.100:8010. 
If you need expose more ports you can add them in **docker-compose.yml** file.

### Scale Thor and Roxie instances
To add a new Thor or Roxie, issue the following:
```sh
docker-compose scale <service name to add>=<number instance total>
```
For example, to make a total of three Thor containers (each container has one slave): 
```sh
docker-compose scale hpcc-thor=2
Creating and starting 2 ... done
```
You must delete then re-create hpcc-master for this new configuration:
```sh
docker-compose stop hpcc-master
Stopping hpccdocker_hpcc-master_1 ... done

docker-compose rm hpcc-master
Going to remove hpccdocker_hpcc-master_1
Are you sure? [yN] y
Removing hpccdocker_hpcc-master_1 ... done

docker-compose run -d -p 8010:8010 hpcc-master
hpccdocker_hpcc-master_run_1
```

On CentOS you may need to login to hpcc-master to manually start the cluster:
 1. Find hpcc-master container id (first column): ```docker ps | grep hpcc-master```
 2. Login interactive shell: ```docker exec -i -t --privileged -e "container=docker" <id> /bin/bash```
 3. Start HPCC cluster: ```sudo /opt/HPCCSystems/sbin/hpcc-run start```.
Even though the login shell is for root, the "USER" variable is not defined which is why we must use "sudo" here.  We will fix this with the id instead of the USER variable in future hpcc-run.sh code.

### Stop the cluster:
```sh
docker-compose kill
Killing hpccdocker_hpcc-thor_2 ... done
Killing hpccdocker_hpcc-thor_1 ... done
Killing hpccdocker_hpcc-roxie_1 ... done

docker-compose rm (type 'y' when prompt)
Going to remove hpccdocker_hpcc-thor_2, hpccdocker_hpcc-thor_1, hpccdocker_hpcc-roxie_1
Are you sure? [yN]y
Removing hpccdocker_hpcc-thor_2 ... done
Removing hpccdocker_hpcc-thor_1 ... done
Removing hpccdocker_hpcc-roxie_1 ... done
```

Above can be done with one command
```sh
docker-compose down
```



To restart hpcc-master you must run docker commands to stop and remove it:
```sh
docker ps
e1324676a4cf        hpccsystems/platform-ce:5.4.8-1trusty   "bash -c 'cd /tmp; /t"   7 minutes ago       Up 7 minutes 

docker stop e1324676a4cf
e1324676a4cf

docker rm  e1324676a4cf
e1324676a4cf
```
There is a script 'clean_run.sh" which can do this, however it will remove all containers.


       
### Customerize network
By default the containers use a network 172.x  Docker bridge network. On Windows and Mac Docker machines run on a Virtualbox VM these 172.x ip addresses can not be accessed on Windows and Mac. With Docker-compose 1.6.2+ you can create a new network to work around this.
Docker-compose 1.6.2 requires Docker 1.10.2+. All of these are available with [Docker Toolbox 1.10.2a or later](https://github.com/docker/toolbox) package which is not released yet. You can however, build it yourself.

**docker-compose-network.yml** shows how to use a user defined network "hpccbridge" can be created with '''docker network create'''
For example:

```sh
docker network create --driver=bridge --gateway=192.168.60.1  --subnet=192.168.60.1/24 hpccbridge
```
Type '''docker network create -h``` for more options.

When using user defined network container ips are no longer published in the environment variable and in /etc/hosts. So our method of collecting ips in run_master.sh doesn't work.  
To configure the cluster you need login to master instance:
```sh
docker exec -i -t <master instance id> bash
```
Go to /tmp and make sure ips.txt has local eth0 ip, and thor_ips.txt has all the Thor instances ips and roxie_ips.txt has all Roxie instances ips. You can get an instance ip with ```docker inspect <container id>```
To configure the HPCC cluster:
```sh
./run_master.sh
```

## Known issues
### containers ips are not inserted to /etc/hosts
This probably related to firewall setting on the host linux: https://github.com/docker/docker/issues/16137. Even ping and 'getent hosts <service name>' can get ip but it will be difficult if there are multiple containers with a same service name. For example, 2 Thor nodes.  

## Build HPCC Docker images

Checkout the git repository:
```sh
git clone https://github.com/xwang2713/HPCC-Docker.git
```
Check if the image already exists locally or not:
```sh
docker images
```
If the "REPOSITORY" and 'TAG' fields are the same as the ones you want to build, you need remove existing ones first:
```sh
docker rmi <IMAGE ID>
```
Create the build directory.  For example,  *build* and cd into it.
Depending on which you want to build (Ubuntu Trusty or CentOS 7 and HPCC version), you can use a help script
under HPCC-Docker or modify them or call HPCC-Docker/build.sh. For example to build HPCC 5.4.8-1 on Trusty:
```sh
../HPCC-Docker/build.sh -l <Linux codename> -s <base image tag suffix> -v <HPCC full version>. 
For example,
../HPCC-Docker/build.sh -l trusty -s hpcc5 -v 6.0.0-1

```
If every build runs OK, the output will display "successfully ....".
Docker images will show:
```sh
docker images
```
