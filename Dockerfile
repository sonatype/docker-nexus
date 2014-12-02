FROM       progrium/busybox 
MAINTAINER Sonatype <cloud-ops@sonatype.com>

RUN opkg-install curl ca-certificates

#
# Java installation
#

ENV JAVA_INSTALL_DIR /usr/jdk1.7.0_71

RUN curl --silent --location --retry 3 \
    --cacert /etc/ssl/certs/GeoTrust_Global_CA.crt \
    --header "Cookie: oraclelicense=accept-securebackup-cookie;" \
    "http://download.oracle.com/otn-pub/java/jdk/7u71-b14/jdk-7u71-linux-x64.tar.gz" \
  | gunzip \
  | tar x -C /usr/ \
  && ln -s $JAVA_INSTALL_DIR /usr/java \
  && rm -rf $JAVA_INSTALL_DIR/src.zip $JAVA_INSTALL_DIR/javafx-src.zip $JAVA_INSTALL_DIR/man

ENV JAVA_HOME /usr/java
ENV PATH ${PATH}:${JAVA_HOME}/bin

#
# Nexus installation
#

# The version of nexus to install
ENV NEXUS_VERSION 2.11.0-02

# This is where nexus writes data- should be persistent storage
ENV SONATYPE_WORK /sonatype-work

# Where to install nexus
ENV NEXUS_INSTALL_DIR /opt/sonatype/nexus

RUN mkdir -p ${NEXUS_INSTALL_DIR} \
  && curl --fail --silent --location --retry 3 \
    http://download.sonatype.com/nexus/oss/nexus-${NEXUS_VERSION}-bundle.tar.gz \
  | gunzip \
  | tar x -C /tmp nexus-${NEXUS_VERSION} \
  && mv /tmp/nexus-${NEXUS_VERSION}/* ${NEXUS_INSTALL_DIR}/ \
  && rm -rf /tmp/nexus-${NEXUS_VERSION} \
  && sed -e "s|^nexus-work=.*|nexus-work=${SONATYPE_WORK}|" \
    -e "s|^nexus-webapp-context-path=.*|nexus-webapp-context-path=/|" \
    -i ${NEXUS_INSTALL_DIR}/conf/nexus.properties

RUN adduser -h "${SONATYPE_WORK}" -g "nexus role account" -s /bin/false -S -u 200 nexus

VOLUME ${SONATYPE_WORK}

ENV JVM_OPTIONS -server -XX:MaxPermSize=192m -Djava.net.preferIPv4Stack=true -Xms256m -Xmx1g

EXPOSE 8081
USER nexus
WORKDIR ${NEXUS_INSTALL_DIR}
CMD java \
  ${JVM_OPTIONS} \
  -cp conf/:`(echo lib/*.jar) | sed -e "s/ /:/g"` \
  org.sonatype.nexus.bootstrap.Launcher ./conf/jetty.xml ./conf/jetty-requestlog.xml
