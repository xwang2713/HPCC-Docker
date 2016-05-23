#!/bin/bash

SCRIPT_DIR=$(dirname $0)

usage()
{
   echo ""
   echo "Usage: build.sh -b <url> -d <HPCC Docker directory> -l <linux codename> -p <project> "
   echo "                -s <base image suffix> -v <fullversion>"
   echo "  -b: base url of HPCC project image"
   echo "  -d: HPCC Docker repository directory"
   echo "  -l: Linux codename. Supported: trusty,xenial, el7, el6."
   echo "  -p: HPCC project name: ce or ce-plugins. Default is ce"
   echo "  -s: base linux image tag suffix. The default is  hpcc<fullvesion_major>."
   echo "  -v: full version. For example: 6.0.0-rc1 or 5.6.2-1"
   echo ""
   exit
}

# http://10.176.32.10/builds/CE-Candidate-5.4.6/bin/platform/
base_url=http://cdn.hpccsystems.com/releases
#base_url=http://10.240.32.242/builds

codename=
project=ce
tag=
template=
hpcc_docker_dir=../HPCC-Docker
base_suffix=

while getopts "*b:d:l:p:s:v:" arg
do
    case "$arg" in
       b) base_url="$OPTARG"
          ;;
       d) hpcc_docker_dir="$OPTARG"
          ;;
       l) codename="$OPTARG"
          ;;
       p) project="$OPTARG"
          ;;
       s) base_suffix="$OPTARG"
          ;;
       v) fullversion="$OPTARG"
          ;;
       ?) usage
          ;;
    esac
done

if [ -z "${base_url}" ] || [ -z "${codename}" ] || [ -z "${fullversion}" ] 
then
    usage
fi

template=${hpcc_docker_dir}/hpcc/${codename}/Dockerfile.template.${project}
project="platform-${project}"
file_name_suffix=
package_type

case "$codename" in
   "el6" | "el7" )
     file_name_suffix="${fullversion}.${codename}.x86_64.rpm"
     tag="${fullversion}.${codename}"
     package_type=rpm
     ;;
   "trusty" | "xenial" )
     file_name_suffix="${fullversion}${codename}_amd64.deb"
     tag="${fullversion}${codename}"
     package_type=deb
     ;;
    * ) echo "Unsupported codename $codename" 
        exit 1
esac

[ -z "$base_suffix" ] && base_suffix="hpcc$(echo ${fullversion} | cut -d'.' -f1)"

PLATFORM_TYPE=$(echo $project | cut -d'-' -f2 | tr [a-z] [A-Z])
VERSION=$(echo $fullversion | cut -d'-' -f1)

echo "Project: ${project}, Full Version: ${fullversion}, version: ${VERSION}, Tag: $tag"
echo "BASE URL: $base_url"
echo "Template: $template"
echo "file_name_suffix: $file_name_suffix"


cp ${SCRIPT_DIR}/run_master.sh .
cp ${SCRIPT_DIR}/get_ips.* .

[ -e Dockerfile ] && rm -rf Dockerfile

sed "s|<URL_BASE>|${base_url}|g; \
     s|<PLATFORM_TYPE>|${PLATFORM_TYPE}|g; \
     s|<VERSION>|${VERSION}|g; \
     s|<BASE_SUFFIX>|${base_suffix}|g; \
     s|<FILE_NAME_SUFFIX>|${file_name_suffix}|g"   < ${template} > Dockerfile

eval "$(docker-machine env default)"
pwd
echo "docker build -t hpccsystems/${project}:${tag} ."
docker build -t hpccsystems/${project}:${tag} .


echo ""
echo "Test docker image"
if [ "$package_type" = "deb" ]
then
   #echo "For Ubuntu:"
   echo "    docker run -t -i -p 8010:8010 hpccsystems/${project}:${tag} /bin/bash"
   echo "    sudo service ssh start"
   echo "    sudo service hpcc-init start"
else
   #echo "For CentOS:"
   echo "    docker run --privileged -t -i -e "container=docker" -p 8010:8010 hpccsystems/${project}:${tag} /bin/bash"
   echo "    /usr/sbin/sshd -D &"
   echo "    /etc/init.d/hpcc-init start"
fi

echo ""
echo "Push the image to Docker Hub"
echo "docker push hpccsystems/${project}:${tag}"
