#!/bin/bash

docker ps  | while read line
do
  id=$(echo $line | cut -d ' ' -f1)
  [ "CONTAINER" = "$id" ] && continue
  docker stop $id
done

docker ps -a | while read line
do
  id=$(echo $line | cut -d ' ' -f1)
  [ "CONTAINER" = "$id" ] && continue
  docker rm $id
done
