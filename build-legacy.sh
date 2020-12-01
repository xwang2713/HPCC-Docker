#!/bin/bash

INPUT_VERSION=7.12.2-1
CEDF_DIR=/home/ming/work/Docker/HPCC-22602-add-dockerfile/containers/docker
LNDF_DIR=/home/ming/work/Docker/LN-22602-add-dockerfile/containers/docker



# build CE Platform

build_platform()
{
echo "Build CE Platform"
sudo docker build -t hpccsystemslegacy/platform:${INPUT_VERSION} --build-arg version=${INPUT_VERSION} ./platform
sudo docker push hpccsystemslegacy/platform:${INPUT_VERSION}
sudo docker build -t hpccsystemslegacy/platform:latest --build-arg version=${INPUT_VERSION} ./platform
sudo docker push hpccsystemslegacy/platform:latest

#sudo docker build -t hpccsystems/platform:${INPUT_VERSION} --build-arg version=${INPUT_VERSION} ./platform
#sudo docker push hpccsystems/platform:${INPUT_VERSION}
#sudo docker build -t hpccsystems/platform:latest --build-arg version=${INPUT_VERSION} ./platform
#sudo docker push hpccsystems/platform:latest

echo "Build Admin"
cd deployment/admin
sudo docker build -t hpccsystemslegacy/hpcc-admin:${INPUT_VERSION} --build-arg version=${INPUT_VERSION} .
sudo docker push hpccsystemslegacy/hpcc-admin:${INPUT_VERSION}
sudo docker build -t hpccsystemslegacy/hpcc-admin:latest --build-arg version=${INPUT_VERSION} .
sudo docker push hpccsystemslegacy/hpcc-admin
cd $CEDF_DIR
}


build_clienttools() 
{
echo "Build CE Clienttools"
sudo docker build -t hpccsystemslegacy/clienttools:${INPUT_VERSION} --build-arg version=${INPUT_VERSION} ./clienttools
sudo docker push hpccsystemslegacy/clienttools:${INPUT_VERSION}
sudo docker build -t hpccsystemslegacy/clienttools:latest --build-arg version=${INPUT_VERSION} ./clienttools
sudo docker push hpccsystemslegacy/clienttools:latest

#sudo docker build -t hpccsystems/clienttools:${INPUT_VERSION} --build-arg version=${INPUT_VERSION} ./clienttools
#sudo docker push hpccsystems/clienttools:${INPUT_VERSION}
#sudo docker build -t hpccsystems/clienttools:latest --build-arg version=${INPUT_VERSION} ./clienttools
#sudo docker push hpccsystems/clienttools:latest
}

build_vm() {
echo "Build VM"
pwd
sudo docker build -t hpccsystemslegacy/vm:${INPUT_VERSION} --build-arg version=${INPUT_VERSION} ./vm
sudo docker push hpccsystemslegacy/vm:${INPUT_VERSION}
sudo docker build -t hpccsystemslegacy/vm:latest --build-arg version=${INPUT_VERSION} ./vm
sudo docker push hpccsystemslegacy/vm:latest

#sudo docker build -t hpccsystems/vm:${INPUT_VERSION} --build-arg version=${INPUT_VERSION} ./vm
#sudo docker push hpccsystems/vm:${INPUT_VERSION}
#sudo docker build -t hpccsystems/vm:latest --build-arg version=${INPUT_VERSION} ./vm
#sudo docker push hpccsystems/vm:latest
}


cd $CEDF_DIR
build_platform
build_clienttools
build_vm
