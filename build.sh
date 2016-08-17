#!/bin/bash

SCRIPT_DIR=$(dirname $0)

usage()
{
   echo ""
   echo "Usage: build.sh -b <url> -d <HPCC Docker directory> -l <linux codename> -p <project> "
   echo "                -s <base image suffix> -v <fullversion> -n"
   echo "  -b: base url of HPCC project image"
   echo "  -d: HPCC Docker repository directory"
   echo "  -l: Linux codename. Supported: trusty,xenial, el7, el6."
   echo "  -p: HPCC project name: ce or ce-plugins. Default is ce"
   echo "  -s: base linux image tag suffix. The default is hpcc<fullvesion_major>."
   echo "      hpcc5 for el7 and trusty and hpcc6 for xenial."
   echo "  -t: tag. By default it will use fullversion and codename"
   echo "      It is useful to create a \"latest\" tag to allow update "
   echo "  -n: build nagios monitoring for HPCC."
   echo "      Currently supported on el6 and xenial (16.04) only."
   echo "  -v: full version. For example: 6.0.0-rc1 or 5.6.2-1"
   echo ""
   exit
}

#http://10.240.32.242/builds/CE-Candidate-5.4.6/bin/platform/
base_url=http://cdn.hpccsystems.com/releases
#base_url=http://10.240.32.242/builds

codename=
project=ce
tag=
template=
hpcc_docker_dir=../HPCC-Docker
base_suffix=
build_nagios=false

while getopts "*b:d:l:p:s:t:v:n" arg
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
       t) tag="$OPTARG"
          ;;
       v) fullversion="$OPTARG"
          ;;
       n) build_nagios=true
	  ;;
       ?) usage
          ;;
    esac
done

if [ -z "${base_url}" ] || [ -z "${codename}" ] || [ -z "${fullversion}" ] 
then
    usage
fi
echo "build_nagios: ${build_nagios}"
if [ "$build_nagios" == "true" ]
then
    template=${hpcc_docker_dir}/hpcc/${codename}/Dockerfile.template.nagios.${project}
else
    template=${hpcc_docker_dir}/hpcc/${codename}/Dockerfile.template.${project}
fi
project="platform-${project}"
file_name_suffix=
package_type=
echo "Linux code name: ${codename}"
case "$codename" in
   "el6" | "el7" )
     file_name_suffix="${fullversion}.${codename}.x86_64.rpm"
     [ -z "$tag" ] && tag="${fullversion}.${codename}"
     package_type=rpm
     ;;
   "trusty" | "xenial" )
     file_name_suffix="${fullversion}${codename}_amd64.deb"
     [ -z "$tag" ] && tag="${fullversion}${codename}"
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


cp ${SCRIPT_DIR}/run_*.sh .
cp ${SCRIPT_DIR}/start_*.sh .
cp ${SCRIPT_DIR}/config_hpcc.sh .
cp ${SCRIPT_DIR}/get_ips.* .

[ -e Dockerfile ] && rm -rf Dockerfile

sed "s|<URL_BASE>|${base_url}|g; \
     s|<PLATFORM_TYPE>|${PLATFORM_TYPE}|g; \
     s|<VERSION>|${VERSION}|g; \
     s|<BASE_SUFFIX>|${base_suffix}|g; \
     s|<FILE_NAME_SUFFIX>|${file_name_suffix}|g"   < ${template} > Dockerfile

eval "$(docker-machine env default)"
pwd
if [ "$build_nagios" = "true" ]
then
     echo "docker build -t hpccsystems/${project}_nagios:${tag} ."
     docker build -t hpccsystems/${project}_nagios:${tag} .
else
     echo "docker build -t hpccsystems/${project}:${tag} ."
     docker build -t hpccsystems/${project}:${tag} .
fi


echo ""
echo "Test docker image"
if [ "$package_type" = "deb" ]
then
   #echo "For Ubuntu:"
if [ "$build_nagios" = "true" ]
then
   echo "    docker run -t -i --privileged -p 8010:8010 hpccsystems/${project}_nagios:${tag} /bin/bash"
else
   echo "    docker run -t -i --privileged -p 8010:8010 hpccsystems/${project}:${tag} /bin/bash"
fi
   echo "    sudo service ssh start"
   echo "    sudo /etc/init.d/hpcc-init start"
else
   #echo "For CentOS:"
if [ "$build_nagios" = "true" ]
then
   echo "    docker run --privileged -t -i -e "container=docker" -p 8010:8010 hpccsystems/${project}_nagios:${tag} /bin/bash"
else
   echo "    docker run --privileged -t -i -e "container=docker" -p 8010:8010 hpccsystems/${project}:${tag} /bin/bash"
fi
   echo "    /usr/sbin/sshd &"
   echo "    /etc/init.d/hpcc-init start"
fi

echo ""
echo "Push the image to Docker Hub"
echo "docker push hpccsystems/${project}:${tag}"
