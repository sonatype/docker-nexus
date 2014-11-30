#/bin/sh
#
#
# Download and install Sonatype Nexus
#
# - download Nexus from http://download.sonatype.com
# - install to `/opt/sonatype/nexus`
# - create & configure a work directory `$SONATYPE_WORK`
# - create a nexus role account w/ home dir `$SONATYPE_WORK`
# - create a simple start script (`/opt/sonatype/nexus/bin/start.sh`) which invokes the JVM
#   with `$JVM_OPTIONS`.

set -o errexit

# The version of nexus to install
NEXUS_VERSION=${NEXUS_VERSION:-"2.10.0-02"}

# This is where Nexus writes data- should be persistent storage
SONATYPE_WORK=${SONATYPE_WORK:-"/sonatype-work"}

# Options to pass the the JVM running nexus
JVM_OPTIONS=${JVM_OPTIONS:-"-server -XX:MaxPermSize=192m -Djava.net.preferIPv4Stack=true -Xms256m -Xmx2g -Dcom.sun.jndi.ldap.connect.pool.protocol='plain ssl'"}

INSTALL_DIR="/opt/sonatype/nexus"

USER="nexus"

_add_user() {
  /usr/sbin/useradd -r -u 200 -m -c "nexus role account" -d ${SONATYPE_WORK} -s /bin/bash ${USER}
}

_fetch_nexus() {
  if [ ! -e /tmp/nexus.tar.gz ]; then
    curl -o /tmp/nexus.tar.gz http://download.sonatype.com/nexus/oss/nexus-${NEXUS_VERSION}-bundle.tar.gz
  fi
}

_install_nexus() {
  test -d ${INSTALL_DIR} && rm -rf ${INSTALL_DIR}
  mkdir -p ${INSTALL_DIR}
  tar -C /tmp -xzf /tmp/nexus.tar.gz nexus-${NEXUS_VERSION}
  mv /tmp/nexus-${NEXUS_VERSION}/* ${INSTALL_DIR}
}

_create_workdir() {
  test -d ${SONATYPE_WORK} || mkdir -p ${SONATYPE_WORK}
  chown -R ${USER} ${SONATYPE_WORK}
}

_create_initscript() {
  test -d ${INSTALL_DIR}/bin || mkdir -p ${INSTALL_DIR}/bin

  cat <<EOF > ${INSTALL_DIR}/bin/start.sh
#!/bin/bash

cd /opt/sonatype/nexus
exec java \
  -Dnexus-work=${SONATYPE_WORK} \
  -Dnexus-webapp-context-path=/ \
  ${JVM_OPTIONS} \
  -cp conf/:\`(echo lib/*.jar) | sed -e "s/ /:/g"\` \
  org.sonatype.nexus.bootstrap.Launcher ./conf/jetty.xml ./conf/jetty-requestlog.xml
EOF

  chmod 755 ${INSTALL_DIR}/bin/start.sh

}

_cleanup() {
  test -e /tmp/nexus.tar.gz && rm -f /tmp/nexus.tar.gz
  test -e /tmp/nexus-${NEXUS_VERSION} && rm -rf /tmp/nexus-${NEXUS_VERSION}
}

main() {
  _add_user
  _fetch_nexus
  _install_nexus
  _create_workdir
  _create_initscript
  _cleanup
}

main $@
