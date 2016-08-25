FROM registry.access.redhat.com/rhel7/rhel

EXPOSE 8081

ENV NEXUS_VERSION 2.13.0-01
ENV NEXUS_HOME /opt/nexus/nexus
ENV NEXUS_WORK /sonatype-work
ENV NEXUS_REPOS /repositories


# Run Yum Update
RUN yum install -y java-1.8.0-openjdk-devel tar  \
  && yum clean all

RUN mkdir -p ${NEXUS_HOME} \
  && curl --fail --silent --location --retry 3 \
    https://download.sonatype.com/nexus/professional-bundle/nexus-professional-${NEXUS_VERSION}-bundle.tar.gz \
  | gunzip \
  | tar x -C /tmp nexus-professional-${NEXUS_VERSION} \
  && mv /tmp/nexus-professional-${NEXUS_VERSION}/* ${NEXUS_HOME}/ \
  && rm -rf /tmp/nexus-professional-${NEXUS_VERSION} \
  && chmod 777 $NEXUS_HOME \
   && mkdir -p $NEXUS_WORK && chmod -R 777 $NEXUS_WORK \
   && mkdir -p $NEXUS_REPOS && chmod -R 777 $NEXUS_REPOS \
   && groupadd -r nexus -g 185 && useradd -u 185 -r -g nexus -m -d /home/jboss -s /sbin/nologin -c "Nexus user" nexus

COPY scripts/fix-permissions.sh scripts/startup.sh /usr/local/bin/
COPY conf/nexus.xml $NEXUS_HOME/conf/

RUN chmod 755 /usr/local/bin/fix-permissions.sh \
  && /usr/local/bin/fix-permissions.sh /opt/nexus \
  && /usr/local/bin/fix-permissions.sh $NEXUS_WORK \
  && /usr/local/bin/fix-permissions.sh $NEXUS_REPOS \
  && /usr/local/bin/fix-permissions.sh $NEXUS_HOME/conf \
  && /usr/local/bin/fix-permissions.sh /usr/local/bin/startup.sh


VOLUME ["/sonatype-work"]
VOLUME ["/repositories"]

WORKDIR $NEXUS_HOME

USER nexus

WORKDIR $NEXUS_HOME
ENV CONTEXT_PATH /
ENV MAX_HEAP 768m
ENV MIN_HEAP 256m
ENV JAVA_OPTS -server -XX:MaxPermSize=192m -Djava.net.preferIPv4Stack=true
ENV LAUNCHER_CONF ${NEXUS_HOME}/conf/jetty.xml ${NEXUS_HOME}/conf/jetty-requestlog.xml

CMD /usr/local/bin/startup.sh
