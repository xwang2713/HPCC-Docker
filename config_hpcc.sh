#!/bin/bash

SCRIPT_DIR=$(dirname $0)

function get_roxie_ips()
{
   max_index=${MAX_ROXIE_INDEX}
   [ -z "$max_index" ] && max_index=20
   touch roxie_ips.txt
   for i in $(seq 1 $max_index)
   do
      ip=$(getent hosts hpcc-roxie_${i} | cut -d' ' -f1)
      [ -n "$ip" ] && echo "${ip}" >> roxie_ips.txt
   done
}

function get_thor_ips()
{
   max_index=${MAX_THOR_INDEX}
   [ -z "$max_index" ] && max_index=20
   touch thor_ips.txt
   for i in $(seq 1 $max_index)
   do
      ip=$(getent hosts hpcc-thor_${i} | cut -d' ' -f1)
      [ -n "$ip" ] && echo "${ip}" >> thor_ips.txt
   done
}

function create_ips_string()
{
   IPS=
   [ ! -e "$1" ] &&  return
   while read ip
   do
      ip=$(echo $ip | sed 's/[[:space:]]//g') 
      [ -n "$ip" ] && IPS="${IPS}${ip}\;"
   done < $1
}

#------------------------------------------
# Need root or sudo
#
SUDOCMD=
[ $(id -u) -ne 0 ] && SUDOCMD=sudo


#------------------------------------------
# LOG
#
LOG_FILE=/tmp/run_master.log
touch ${LOG_FILE}
exec 2>$LOG_FILE
set -x


#------------------------------------------
# Start sshd
#
ps -efa | grep -v sshd |  grep -q sshd
[ $? -ne 0 ] && $SUDOCMD mkdir -p /var/run/sshd; $SUDOCMD  /usr/sbin/sshd -D &

#------------------------------------------
# Collect conainters' ips
#

if [ -z "$1" ] || [ "$1" != "-x" ]
then
   if [ -z "${KUBERNETES_SERVICE_HOST}" ]
   then
      grep -e "[[:space:]]hpcc-thor_[[:digit:]][[:digit:]]*" /etc/hosts | awk '{print $1}' > thor_ips.txt
      grep -e "[[:space:]]hpcc-roxie_[[:digit:]][[:digit:]]*" /etc/hosts | awk '{print $1}' > roxie_ips.txt
      # If no thor and roxie wroten to /etc/hosts "links" setting in docker-compose.yml probably doesn't work 
      # For work-around we just iterate with "getent".
      if [ ! -s thor_ips.txt ] &&  [ ! -s roxie_ips.txt ]  
      then
          get_roxie_ips
          get_thor_ips
      fi

      local_ip=$(ifconfig eth0 | sed -n "s/.*inet addr:\(.*\)/\1/p" | awk '{print $1}')
      [ -z "$local_ip" ] && local_ip=$(ifconfig eth0 | sed -n "s/.*inet \(.*\)/\1/p" | awk '{print $1}')
      echo "$local_ip"  > ips.txt
   else
      ${SCRIPT_DIR}/get_ips.sh
      ${SCRIPT_DIR}/get_ips.py
   fi
fi

cat roxie_ips.txt >> ips.txt
cat thor_ips.txt >> ips.txt
#cat ips.txt


#------------------------------------------
# Parameters to envgen
#
HPCC_HOME=/opt/HPCCSystems
CONFIG_DIR=/etc/HPCCSystems
ENV_XML_FILE=environment.xml
IP_FILE=ips.txt
thor_nodes=$(cat thor_ips.txt | wc -l)
roxie_nodes=$(cat roxie_ips.txt | wc -l)
support_nodes=1
slaves_per_node=1
[ -n "$SLAVES_PER_NODE" ] && slaves_per_node=${SLAVES_PER_NODE}
[ -z "$thor_nodes" ] && thor_nodes=0
[ -z "$roxie_nodes" ] && roxie_nodes=0

create_ips_string roxie_ips.txt
roxie_ips="roxie $IPS"

cmd="$SUDOCMD ${HPCC_HOME}/sbin/envgen -env ${CONFIG_DIR}/${ENV_XML_FILE}   \
-override roxie,@roxieMulticastEnabled,false -override thor,@replicateOutputs,true \
-override esp,@method,htpasswd -override thor,@replicateAsync,true                  \
-ip $local_ip -thornodes ${thor_nodes} -slavesPerNode ${slaves_per_node}       \
-roxienodes ${roxie_nodes} -supportnodes ${support_nodes} -roxieondemand 1" 

if [ $thor_nodes -gt 0 ]
then
   create_ips_string thor_ips.txt
   cmd="$cmd -assign_ips thor $IPS"
fi

if [ $roxie_nodes -gt 0 ]
then
   create_ips_string roxie_ips.txt
   cmd="$cmd -assign_ips roxie $IPS"
fi

#------------------------------------------
# Generate environment.xml
#
echo "$cmd" 
eval "$cmd"

#------------------------------------------
# Transfer environment.xml to cluster 
# containers
#
$SUDOCMD   su - hpcc -c "/opt/HPCCSystems/sbin/hpcc-push.sh \
-s /etc/HPCCSystems/environment.xml -t /etc/HPCCSystems/environment.xml -x"

#------------------------------------------
# Start hpcc 
#
# Need force to use sudo for now since $USER is not defined:
# Should fix it in Platform code to use id instead of $USER
# Need stop first since if add contaners other thor and roxie containers are already up.
# Force them to read environemnt.xml by stop and start
$SUDOCMD   ${HPCC_HOME}/sbin/hpcc-run.sh stop
$SUDOCMD   ${HPCC_HOME}/sbin/hpcc-run.sh start


set +x
$SUDOCMD /opt/HPCCSystems/sbin/configgen -env /etc/HPCCSystems/environment.xml -listall2
echo "HPCC cluster configuration is done."
