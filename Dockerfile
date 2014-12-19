FROM       dockerfile/java:oracle-java7
MAINTAINER Sonatype <cloud-ops@sonatype.com>

# The version of nexus to install
ENV NEXUS_VERSION 2.11.1-01

RUN mkdir -p /opt/sonatype/nexus \
  && curl --fail --silent --location --retry 3 \
    http://download.sonatype.com/nexus/oss/nexus-${NEXUS_VERSION}-bundle.tar.gz \
  | gunzip \
  | tar x -C /tmp nexus-${NEXUS_VERSION} \
  && mv /tmp/nexus-${NEXUS_VERSION}/* /opt/sonatype/nexus/ \
  && rm -rf /tmp/nexus-${NEXUS_VERSION}

RUN useradd -r -u 200 -m -c "nexus role account" -d /sonatype-work -s /bin/false nexus

VOLUME /sonatype-work

EXPOSE 8081
USER nexus
WORKDIR /opt/sonatype/nexus
CMD java \
  -server -XX:MaxPermSize=192m -Djava.net.preferIPv4Stack=true -Xms256m -Xmx1g \
  -Dnexus-work=/sonatype-work -Dnexus-webapp-context-path=/ \
  -cp conf/:`(echo lib/*.jar) | sed -e "s/ /:/g"` \
  org.sonatype.nexus.bootstrap.Launcher ./conf/jetty.xml ./conf/jetty-requestlog.xml
