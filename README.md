HPCC-Docker Images and Simple Deployment
========================================
Refernce https://hub.docker.com/r/hpccsystems/platform-ce/ for HPCC Docker images usage

Deploy a HPCC Cluster with Docker Compose
==========================================================
The default docker compose configuration file docker-compose.yml defines three servcies: hpcc-master, 
hpcc-roxie and hpcc-thor. hpcc-master will host dali, esp dfuserver, etc. The default HPCC image is for Ubuntu Trusty.
You can change to othr supplied images or build a new one yourself.

1. Checkout this repository. The default repository directory is HPCC-Docker
2. Go inside HPCC-Docker directory. This directory should have a docker-compose.yml file otherwise you need "-f" option 
when start the cluster
3. To start the cluster:  docer-compse up -d
4. To check the cluster status:  docker-compose ps
5. To verify and play with HPCC Platform: http://<host ip>:8010
6. To add new thor or roxie use "docker-compose scale <service name to add>=<number instance total>"
For example to make total three thor containter (each container has one slave): docker-compose scale hpcc-thor=3
7. You need delete/re-create hpcc-master for this new configuration
   1  docker-compose stop hpcc-master
   2  docker-compose rm hpcc-master
   3  docker-compose run -d -p <mapped port on host>:8010 hpcc-master
   4  On CentOS you may need login to hpcc-master to manually start the cluser:
       1. Find hpcc-master container id (first column): docker ps | grep hpcc-master
       2. Login interactive shell: docker exec -i -t --privileged -e "container=docker" <id> /bin/bash
       3. Start HPCC cluster: sudo /opt/HPCCSystems/sbin/hpcc-run start.
          Eventhough login shell is for root but "USER" variable is not defined which is why we need use "sudo" here.
          We will fix with id instead USER varialbe in future hpcc-run.sh code.
8. To stop the cluster:
   1. docker-compose kill
   2. docker-compose rm (type 'y' when prompt)
   3. If restart hpcc-master you need run 'docker stop <id>" and "docker rm <id>" to clean it. There is help 
   script 'clean_run.sh" can do it but just remmeber which will remove all containers.
       
        

Build HPCC Docker images
========================
1. Checkout this git repository. Assume the directory name is HPCC-Docker
2. Create build directory, for example build and go inside of it.
3. Depends on which you want to build (Ubuntu Trusty or CentOS 7 and HPCC version), you can use help script
under HPCC-Docker or modify them or call HPCC-Docker/build.sh. For example to build HPCC 5.4.8-1 on Trusty:
../HPCC-Docker/build_trusty.sh
4. If every build run OK build output will display "successfully ....". "docker images" will show the 
generated image.
