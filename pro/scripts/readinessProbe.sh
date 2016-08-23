#!/bin/sh

: ${NEXUS_URL:=localhost:8081}

set -x

COUNT=120
SLEEP=1

if [ $# -gt 0 ] ; then
    COUNT=$1
fi

if [ $# -gt 1 ] ; then
    SLEEP=$2
fi

# curl -s -H "Accept: application/json" -X GET -H "Content-Type: application/json" -u admin:admin123 http://localhost:8081/internal/ping
while : ; do
    RESULT=$(curl -s -L -o /dev/null -w "%{http_code}" http://${NEXUS_URL})
    if [ ${RESULT} -eq "200" ] ; then
        exit 0;
    fi

    COUNT=$(expr $COUNT - 1)
    if [ $COUNT -eq 0 ] ; then
        exit 1;
    fi
    sleep ${SLEEP}
done
