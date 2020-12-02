#!/bin/bash
##############################################################################
#
#    HPCC SYSTEMS software Copyright (C) 2020 HPCC Systems® .
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
##############################################################################

BUILD_TAG=$(git describe --exact-match --tags)  # The git tag for the images we are building
INPUT_VERSION=$(echo ${BUILD_TAG} | cut -d'_' -f 2)

if [[ -n ${INPUT_USERNAME} ]] ; then
  echo ${INPUT_PASSWORD} | docker login -u ${INPUT_USERNAME} --password-stdin ${INPUT_REGISTRY}
  PUSH=1
fi

label=${INPUT_VERSION}
if [[ "$INPUT_LATEST" = "1" ]] ; then
  LATEST=1
fi

set -e
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd $DIR 2>&1 > /dev/null

push_image() 
{
  local name=$1
  local label=$2
  if [ "$LATEST" = "1" ] ; then
    docker tag hpccsystemslegacy/${name}:${label} hpccsystemslegacy/${name}:latest
    if [ "$PUSH" = "1" ] ; then
      docker push hpccsystemslegacy/${name}:${label}
      docker push hpccsystemslegacy/${name}:latest
    fi
  else
    if [ "$PUSH" = "1" ] ; then
      docker push hpccsystemslegacy/${name}:${label}
    fi
  fi
}

build_image() 
{
  local name=$1
  local label=$2
  local directory=$3

  cd ${directory}
  docker build -t hpccsystemslegacy/${name}:${label} --build-arg version=${label} .
  push_image $name $label

  cd $DIR
}

echo "Build CE Platform"
build_image  platform $label platform

echo "Build Admin"
build_image  hpcc-admin $label deployment/admin

echo "Build CE Clienttools"
build_image  clienttools $label clienttools

echo "Build VM"
build_image  vm $label vm
