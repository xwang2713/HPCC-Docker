FROM centos:6
MAINTAINER Xiaoming Wang <xiaoming.wang@lexisnexis.com>
RUN yum update -y 
RUN yum install -y gcc-c++
RUN yum install -y boost-regex openldap libicu m4 libtool
RUN yum install -y libxslt libxml2 openssh-server openssh-clients 
RUN yum install -y expect libarchive rsync apr apr-util zip tbb
RUN yum install -y wget tar
RUN cd /etc/ssh; wget http://10.176.32.10/data3/software/ssh/ssh_host_keys.tar.gz; tar -zxvf ssh*.gz; rm -rf ssh*.gz
RUN chown root:root /etc/ssh/ssh_host*
