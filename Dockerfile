FROM centos:centos6
MAINTAINER Sonatype <cloud-ops@sonatype.com>

RUN rpm -i http://dl.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
RUN yum update -y;
RUN yum install -y tar java-1.7.0-openjdk; yum clean all

# The version of nexus to install
ENV NEXUS_VERSION 2.11.0-02

# This is where Nexus writes data- should be persistent storage
ENV SONATYPE_WORK /sonatype-work

# Options to pass the the JVM running nexus
# ENV JVM_OPTIONS -server -XX:MaxPermSize=192m -Djava.net.preferIPv4Stack=true -Xms256m -Xmx2g -Dcom.sun.jndi.ldap.connect.pool.protocol='plain ssl'

ADD ./nexus.sh /nexus.sh
RUN /nexus.sh

EXPOSE 8081
USER nexus
WORKDIR /opt/sonatype/nexus
CMD /opt/sonatype/nexus/bin/start.sh
