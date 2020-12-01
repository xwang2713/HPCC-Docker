#!/bin/bash
[ -z "$1" ] && echo "Missing image pattern" && exit
sudo docker rmi -f $(sudo docker images | grep $1 | awk '{print $3}')
