#!/bin/bash

sudo docker rmi -f $(sudo docker images | grep hpccsystems | awk '{print $3}')
