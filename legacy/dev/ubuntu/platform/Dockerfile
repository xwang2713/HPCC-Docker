################################################################################
#    HPCC SYSTEMS software Copyright (C) 2019 HPCC Systems®.
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
################################################################################
From hpccsystems/hpcc-dev:7-focal AS focal-builder
# Usage: sudo docker build -t <image tag> --build-arg branch=<HPCC branch or tag> --build-arg owner=<project owner> .
# The default branch is "master". The default github project owner is "hpcc-systems".
# user/password is used to clone non-public project such as LN.
ARG branch=
ARG owner="hpcc-systems"
ARG user=
ARG password=

WORKDir /hpcc-dev
RUN set -ex; \
   if [ -n "${user}" ] ; \
   then \
      echo "machine github.com login ${user} password ${password}" > ~/.netrc ; \
   else : ;  fi; \
   git clone https://github.com/${owner}/HPCC-Platform.git; \
   cd HPCC-Platform; \
   if [ -n "${branch}" ] ; \
   then \
      rc=$(git tag | grep ${branch}) || : ; \
      if [ -n "$rc" ]; \
      then \
         git fetch && git fetch --tags; \
      else : ; fi; \
      git checkout ${branch}; \
   else : ; fi; \
   git submodule update --init --recursive; \
   cd ..; \
   mkdir -p build; \
   cd build; \
   rm -rf * ; \
   cmake ../HPCC-Platform; \
   make -j 4 ; \
   make package


From hpccsystems/hpcc-base:7-focal

WORKDir /Downloads
COPY --from=0 /hpcc-dev/build/hpccsystems*.deb .
RUN set -ex; \
   apt-get update -y; \
   apt-get install -y iputils-ping curl xterm libarchive13 ; \
   groupadd hpcc && useradd -s /bin/bash -r -m -d /home/hpcc -g hpcc -c "hpcc Runtime User" hpcc ; \
   dpkg -i hpccsystems*.deb; \
   rm -rf  hpccsystems*.deb

EXPOSE 8010 8002 8015 9876 18010 18002 18015 19876

ENTRYPOINT ["/docker-entrypoint.sh"]
CD ["/usr/sbin/sshd", "-D"]
