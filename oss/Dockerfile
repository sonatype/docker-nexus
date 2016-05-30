FROM       java:8-jdk
MAINTAINER Sonatype <cloud-ops@sonatype.com>

ENV NEXUS_VERSION 3.0.0-03

RUN curl --fail --silent --location --retry 3 https://download.sonatype.com/nexus/3/nexus-${NEXUS_VERSION}-unix.sh > nexus.sh \
  && chmod +x nexus.sh \
  && ./nexus.sh -q \
  && rm nexus.sh \
  && rm -rf /var/nexus

RUN useradd -r -u 200 -m -c "nexus role account" -d /var/nexus -s /bin/false nexus

VOLUME /var/nexus

EXPOSE 8081
WORKDIR /var/nexus
USER nexus

CMD /etc/init.d/nexus run-redirect
