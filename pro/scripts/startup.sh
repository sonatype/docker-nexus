#!/bin/bash

# Startup Script

# Copy configuration file if not present
mkdir -p $NEXUS_WORK/conf

if [ ! -f $NEXUS_WORK/conf/nexus.xml ]; then
  cp -f $NEXUS_HOME/conf/nexus.xml $NEXUS_WORK/conf/
fi

# Start Nexus
exec java \
  -Dnexus-work=${NEXUS_WORK} -Dnexus-webapp-context-path=${CONTEXT_PATH} -Dapplication-conf=${NEXUS_HOME}/conf \
  -Xms${MIN_HEAP} -Xmx${MAX_HEAP} \
  -cp '/opt/nexus/nexus/conf/:/opt/nexus/nexus/lib/*' \
  ${JAVA_OPTS} \
  org.sonatype.nexus.bootstrap.Launcher ${LAUNCHER_CONF}