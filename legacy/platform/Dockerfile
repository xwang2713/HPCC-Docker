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
FROM hpccsystemslegacy/hpcc-base

ARG version=
RUN if [ -z "${version}" ] ; then echo Missing HPCC version; exit 1; else : ; fi

RUN set -ex; \
   apt-get update --fix-missing; \
   apt-get install -y iputils-ping curl libcurl3-gnutls xterm libarchive13 gpg ; \
   groupadd hpcc && useradd -s /bin/bash -r -m -d /home/hpcc -g hpcc -c "hpcc Runtime User" hpcc ; \
   export VERSION_MMP=${version%-*}; \
   export PLATFORM_PACKAGE=hpccsystems-platform-community_${version}focal_amd64.deb; \
   wget  "http://d2wulyp08c6njk.cloudfront.net/releases/CE-Candidate-${VERSION_MMP}/bin/platform/${PLATFORM_PACKAGE}"; \
   #echo "$PLATFORM_DOWNLOAD_MD5 ${PLATFORM_PACKAGE}" | md5sum -c -; \
   dpkg -i "${PLATFORM_PACKAGE}" ;\
   apt-get install -f ; \
   rm -rf "${PLATFORM_PACKAGE}"


EXPOSE 8010 8002 8015 9876 18010 18002 18015 19876

#COPY id_rsa* /home/hpcc/.ssh/

#RUN cp -r /home/hpcc/.ssh ~/

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["/usr/sbin/sshd", "-D"]
