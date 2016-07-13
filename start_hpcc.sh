#!/bin/bash
SUDOCMD=
[ $(id -u) -ne 0 ] && SUDOCMD=sudo

#------------------------------------------
# Start sshd
#
ps -efa | grep -v sshd |  grep -q sshd
[ $? -ne 0 ] && $SUDOCMD mkdir -p /var/run/sshd; $SUDOCMD  /usr/sbin/sshd -D &

if [ -e /etc/HPCCSystems/environment.xml ]; then
   $SUDOCMD /etc/init.d/hpcc-init start
fi

#------------------------------------------
# Keep container running
#
if [ -z "$1" ] || [ "$1" != "-x" ]
then
   while [ 1 ] ; do sleep 60; done
fi
