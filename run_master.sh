#!/bin/bash

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
grep -e "[[:space:]]hpcc-thor_[[:digit:]][[:digit:]]*" /etc/hosts | awk '{print $1}' > thor_ips.txt
grep -e "[[:space:]]hpcc-roxie_[[:digit:]][[:digit:]]*" /etc/hosts | awk '{print $1}' > roxie_ips.txt

local_ip=$(ifconfig eth0 | sed -n "s/.*inet addr:\(.*\)/\1/p" | awk '{print $1}')
[ -z "$local_ip" ] && local_ip=$(ifconfig eth0 | sed -n "s/.*inet \(.*\)/\1/p" | awk '{print $1}')
echo "$local_ip"  > ips.txt
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


#------------------------------------------
# Generate environment.xml
#
echo "$SUDOCMD ${HPCC_HOME}/sbin/envgen -env ${CONFIG_DIR}/${ENV_XML_FILE}    \
-ipfile ${IP_FILE} -thornodes ${thor_nodes} -slavesPerNode ${slaves_per_node} \
-roxienodes ${roxie_nodes} -supportnodes ${support_nodes}"

$SUDOCMD "${HPCC_HOME}/sbin/envgen" -env "${CONFIG_DIR}/${ENV_XML_FILE}"            \
-ipfile "${IP_FILE}" -thornodes "${thor_nodes}" -slavesPerNode "${slaves_per_node}" \
-roxienodes "${roxie_nodes}" -supportnodes "${support_nodes}"

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
sudo   ${HPCC_HOME}/sbin/hpcc-run.sh start


#------------------------------------------
# Keep container running
#
while [ 1 ] ; do sleep 60; done 
