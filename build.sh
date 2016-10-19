#!/bin/bash

SCRIPT_DIR=$(dirname $0)

usage()
{
   echo ""
   echo "Usage: build.sh -b <url> -d <HPCC Docker directory> -l <linux codename> -p <project> "
   echo "                -s <base image suffix> -v <fullversion> -n"
   echo "  -b: base url of HPCC project image"
   echo "  -d: HPCC Docker repository directory"
   echo "  -D: use debug build"
   echo "  -l: Linux codename. Supported: trusty,xenial, el7, el6."
   echo "  -p: HPCC project name: ce or plugins. Default is ce"
   echo "  -s: base linux image tag suffix. The default is hpcc<fullvesion_major>."
   echo "      hpcc5 for el7 and trusty and hpcc6 for xenial."
   echo "  -t: tag. By default it will use fullversion and codename"
   echo "      It is useful to create a \"latest\" tag to allow update "
   echo "  -v: full version. For example: 6.0.0-rc1 or 5.6.2-1"
   echo ""
   exit
}

#http://10.240.32.242/builds/CE-Candidate-5.4.6/bin/platform/
#base_url=http://cdn.hpccsystems.com/releases
base_url=http://10.240.32.242/builds
#base_url=http://10.240.32.242/builds/custom/kubernetes

codename=
project=ce
tag=
template=
hpcc_docker_dir=$SCRIPT_DIR
base_suffix=
debug=0

while getopts "*b:d:Dl:p:s:t:v:" arg
do
    case "$arg" in
       b) base_url="$OPTARG"
          ;;
       d) hpcc_docker_dir="$OPTARG"
          ;;
       D) debug=1
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
       ?) usage
          ;;
    esac
done

if [ -z "${base_url}" ] || [ -z "${codename}" ] || [ -z "${fullversion}" ] 
then
    usage
fi

template=${hpcc_docker_dir}/dependencies/${codename}/Dockerfile.template.${project}
if [ "$project" = "ce" ] || [ "$project" = "ee" ] || [ "$project" = "ln" ]
then
  PLATFORM_TYPE=$(echo $project | cut -d'-' -f1 | tr [a-z] [A-Z])
  project="platform-${project}"
fi
file_name_suffix=
package_type=
echo "Linux code name: ${codename}"
version_build_type=$fullversion
[ $debug -eq 1 ] && version_build_type="${fullversion}Debug"
case "$codename" in
   "el6" | "el7" )
     file_name_suffix="${version_build_type}.${codename}.x86_64.rpm"
     [ -z "$tag" ] && tag="${version_build_type}.${codename}"
     package_type=rpm
     ;;
   "trusty" | "xenial" )
     file_name_suffix="${version_build_type}${codename}_amd64.deb"
     [ -z "$tag" ] && tag="${version_build_type}${codename}"
     package_type=deb
     ;;
    * ) echo "Unsupported codename $codename" 
        exit 1
esac

[ -z "$base_suffix" ] && base_suffix="hpcc$(echo ${fullversion} | cut -d'.' -f1)"

VERSION=$(echo $fullversion | cut -d'-' -f1)

echo "Project: ${project}, Full Version: ${version_build_type}, version: ${VERSION}, Tag: $tag"
echo "BASE URL: $base_url"
echo "Template: $template"
echo "file_name_suffix: $file_name_suffix"


cp ${SCRIPT_DIR}/*.sh .
cp ${SCRIPT_DIR}/*.py .

case "$project" in
    wssql)
      cp ${hpcc_docker_dir}/hpcc/wssql/environment.xml .
      ;;

esac
[ -e Dockerfile ] && rm -rf Dockerfile

sed "s|<URL_BASE>|${base_url}|g; \
     s|<PLATFORM_TYPE>|${PLATFORM_TYPE}|g; \
     s|<VERSION>|${VERSION}|g; \
     s|<BASE_SUFFIX>|${base_suffix}|g; \
     s|<FILE_NAME_SUFFIX>|${file_name_suffix}|g"   < ${template} > Dockerfile

#eval "$(docker-machine env default)"
pwd

echo "docker build -t hpccsystems/${project}:${tag} ."
docker build -t hpccsystems/${project}:${tag} .


echo ""
echo "Test docker image"
if [ "$package_type" = "deb" ]
then
   #echo "For Ubuntu:"
   echo "    docker run -t -i --privileged -p 8010:8010 hpccsystems/${project}:${tag} /bin/bash"
   echo "    sudo service ssh start"
   echo "    sudo /etc/init.d/hpcc-init start"
else
   #echo "For CentOS:"
   echo "    docker run --privileged -t -i -e "container=docker" -p 8010:8010 hpccsystems/${project}:${tag} /bin/bash"
   echo "    /usr/sbin/sshd &"
   echo "    /etc/init.d/hpcc-init start"
fi

echo ""
echo "Push the image to Docker Hub"
echo "docker push hpccsystems/${project}:${tag}"
