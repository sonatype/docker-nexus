FROM registry.access.redhat.com/rhel7/rhel
MAINTAINER Sonatype <cloud-ops@sonatype.com>

EXPOSE 8081

ENV NEXUS_VERSION 2.13.0-01
ENV NEXUS_HOME /opt/nexus/nexus
ENV NEXUS_WORK /sonatype-work
ENV NEXUS_REPOS /repositories
ENV APPLICATION_CONF /conf

# Run Yum Update
RUN yum install -y java-1.8.0-openjdk-devel tar  \
  && yum clean all

RUN mkdir -p ${NEXUS_HOME} \
  && curl --fail --silent --location --retry 3 \
    https://download.sonatype.com/nexus/oss/nexus-${NEXUS_VERSION}-bundle.tar.gz \
  | gunzip \
  | tar x -C /tmp nexus-${NEXUS_VERSION} \
  && mv /tmp/nexus-${NEXUS_VERSION}/* ${NEXUS_HOME}/ \
  && rm -rf /tmp/nexus-${NEXUS_VERSION} \
  && chmod 777 $NEXUS_HOME \
  && mkdir -p $NEXUS_WORK && chmod -R 777 $NEXUS_WORK \
  && mkdir -p $NEXUS_REPOS && chmod -R 777 $NEXUS_REPOS \
  && mkdir -p $APPLICATION_CONF && chmod -R 777 $APPLICATION_CONF

RUN useradd -r -u 200 -m -c "nexus role account" -d ${NEXUS_WORK} -s /bin/false nexus

COPY scripts/fix-permissions.sh /usr/local/bin/

RUN chmod 755 /usr/local/bin/fix-permissions.sh \
  && /usr/local/bin/fix-permissions.sh /opt/nexus \
  && /usr/local/bin/fix-permissions.sh $NEXUS_WORK \
  && /usr/local/bin/fix-permissions.sh $NEXUS_REPOS \
  && /usr/local/bin/fix-permissions.sh $NEXUS_HOME/conf \
  && /usr/local/bin/fix-permissions.sh $APPLICATION_CONF

VOLUME ["/sonatype-work"]
VOLUME ["/repositories"]

USER nexus

WORKDIR $NEXUS_HOME
ENV CONTEXT_PATH /
ENV MAX_HEAP 768m
ENV MIN_HEAP 256m
ENV JAVA_OPTS -server -XX:MaxPermSize=192m -Djava.net.preferIPv4Stack=true
ENV LAUNCHER_CONF ${NEXUS_HOME}/conf/jetty.xml ${NEXUS_HOME}/conf/jetty-requestlog.xml

CMD ${JAVA_HOME}/bin/java \
  -Dnexus-work=${NEXUS_WORK} -Dnexus-webapp-context-path=${CONTEXT_PATH} \
  -Dapplication-conf=${APPLICATION_CONF} \
  -Xms${MIN_HEAP} -Xmx${MAX_HEAP} \
  -cp 'conf/:lib/*' \
  ${JAVA_OPTS} \
  org.sonatype.nexus.bootstrap.Launcher ${LAUNCHER_CONF}
