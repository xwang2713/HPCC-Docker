#!/bin/bash

SCRIPT_DIR=$(dirname $0)

function check_update()
{
  if [ -n "$DOWNLOAD_URL" ]
  then
      case $DOWNLOAD_METHOD in
      wget) 
          eval "wget $DOWNLOAD_URL"
          [ $? -ne 0 ] && return 1
          file_name=${DOWNLOAD_URL##*/}
          if [ ${file_name: -7} == ".tar.gz" ] 
          then
              tar -zxf $file_name 
              cd ${file_name%.tar.gz}
          elif [ ${file_name: -4} == ".tar" ] 
          then
              tar -xf $file_name 
              cd ${file_name%.tar}
          elif [ ${file_name: -4} == ".zip" ] 
          then
              unzip $file_name 
              cd ${file_name%.zip}
          else
              echo "Unsupported file extention: $file_name"
             return 1
          fi
          ;;
     
          git | *)
          eval "git clone $DOWNLOAD_URL"
          [ $? -ne 0 ] && return 1
          cd  ${DOWNLOAD_URL##*/}
          ;;
      esac

   fi
}


#------------------------------------------
# LOG
#

LOG_FILE=/tmp/run_master.log
touch ${LOG_FILE}
exec 2>$LOG_FILE
set -x


#------------------------------------------
# Need root or sudo
#
SUDOCMD=
[ $(id -u) -ne 0 ] && SUDOCMD=sudo


#------------------------------------------
# Start sshd
#
ps -efa | grep -v sshd |  grep -q sshd
[ $? -ne 0 ] && $SUDOCMD mkdir -p /var/run/sshd; $SUDOCMD  /usr/sbin/sshd -D &


#------------------------------------------
# Check update
#
check_update
[ $? -ne 0 ] && echo "Update is not available, use default /tmp/config_hpcc.sh"

#------------------------------------------
# Run config_hpcc.sh
#
pwd
./config_hpcc.sh > /tmp/config_hpcc.log 2>&1


#------------------------------------------
# Keep container running
#
if [ -z "$1" ] || [ "$1" != "-x" ]
then
   while [ 1 ] ; do sleep 60; done 
fi
