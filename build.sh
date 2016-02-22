#!/bin/bash

SCRIPT_DIR=$(dirname $0)

usage()
{
   echo ""
   echo "Usage: build.sh -b <url> -d <directory> -f <file name> -p <project> -t <tag>"
   echo "  -b: base url of HPCC project image"
   echo "  -i: docker template file path"
   echo "  -f: HPCC image file name"
   echo "  -p: HPCC project name. Default is platform-ce"
   echo "  -t: docker image tag"
   echo ""
   exit
}

# http://10.176.32.10/builds/CE-Candidate-5.4.6/bin/platform/
base_url=
# /home/hpccbuild/work/docker/hpcc/centos6
# hpccsystems-platform-community_5.4.6-1.el6.x86_64.rpm
file_name=

project=platform-ce
tag=

template=

while getopts "*b:i:f:p:t:" arg
do
    case "$arg" in
       b) base_url="$OPTARG"
          ;;
       i) template="$OPTARG"
          ;;
       f) file_name="$OPTARG"
          ;;
       p) project="$OPTARG"
          ;;
       t) tag="$OPTARG"
          ;;
       ?) usage
          ;;
    esac
done

if [ -z "${base_url}" ] || [ -z "${template}" ] || [ -z "${file_name}" ] || [ -z "${tag}" ]
then
    usage
fi


cp ${SCRIPT_DIR}/run_master.sh .

[ -e Dockerfile ] && rm -rf Dockerfile

sed "s|<URL_BASE>|${base_url}|g; \
     s|<HPCC_IMAGE>|${file_name}|g" < ${template} > Dockerfile

eval "$(docker-machine env default)"
pwd
echo "docker build -t hpccsystems/${project}:${tag} ."
docker build -t hpccsystems/${project}:${tag} .


echo ""
echo "Test docker image"
echo "For Ubuntu:"
echo "    docker run -t -i -p 8010:8010 hpccsystems/${project}:${tag} /bin/bash"
echo "    sudo service ssh start"
echo "    sudo service hpcc-init start"
echo "For CentOS:"
echo "    docker run --privileged -t -i -e "container=docker" -p 8010:8010 hpccsystems/${project}:${tag} /bin/bash"
echo "    /usr/sbin/sshd -D &"
echo "    /etc/init.d/hpcc-init start"
echo ""
echo "Push the image to Docker Hub"
echo "docker push hpccsystems/${project}:${tag}"
