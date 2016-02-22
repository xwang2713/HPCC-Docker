FROM hpccsystems/linux:el6_hpcc5
MAINTAINER Xiaoming Wang <xiaoming.wang@lexisnexis.com>
RUN yum update -y 
RUN wget http://10.176.32.10/builds/CE-Candidate-5.4.6/bin/platform/hpccsystems-platform-community_5.4.6-1.el6.x86_64.rpm
RUN groupadd hpcc
RUN useradd -s /bin/bash -r -m -d /home/hpcc -g hpcc -c "hpcc Runtime User" hpcc
RUN yum install --nogpgcheck -y hpccsystems-platform-community_5.4.6-1.el6.x86_64.rpm

