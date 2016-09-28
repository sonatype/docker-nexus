#!/bin/bash

VERSION="$1"
VERSION="${VERSION,,}"
if [[ ${VERSION} != "pro" ]] && [[ ${VERSION} != "oss" ]]
then
  echo "Usage:"
  echo "  ./init.sh pro"
  echo "  ./init.sh oss"
  exit 1
fi

set -e

SCRIPT_BASE_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Login Information
OSE_CLI_USER="admin"
OSE_CLI_PASSWORD="admin"
OSE_NEXUS_PROJECT="nexus"

# Login to OSE
echo
echo "Logging into OSE..."
echo "=================================="
echo
oc login -u ${OSE_CLI_USER} -p ${OSE_CLI_PASSWORD}

# Create CI Project
echo
echo "Creating new Nexus Project (${OSE_NEXUS_PROJECT})..."
echo "=================================="
echo
oc new-project ${OSE_NEXUS_PROJECT}

echo
echo "Configuring project permissions..."
echo "=================================="
echo
# Grant Default CI Account Edit Access to All Projects and OpenShift Project
oc policy add-role-to-user edit system:serviceaccount:${OSE_NEXUS_PROJECT}:default -n ${OSE_NEXUS_PROJECT}

if [[ ${VERSION} == "oss" ]]
then

  # Process Nexus Template
  echo
  echo "Processing Nexus OSS Template..."
  echo "=================================="
  echo
  oc create -f "${SCRIPT_BASE_DIR}/nexus-oss.json" -n ${OSE_NEXUS_PROJECT}

  sleep 10

  echo
  echo "Starting Nexus OSS binary build..."
  echo "=================================="
  echo
  oc start-build -n ${OSE_NEXUS_PROJECT} nexus-oss --follow

else

  # Process Nexus Template
  echo
  echo "Processing Nexus Pro Template..."
  echo "=================================="
  echo
  oc create -f "${SCRIPT_BASE_DIR}/nexus-pro.json" -n ${OSE_NEXUS_PROJECT}

  sleep 10

  echo
  echo "Starting Nexus Pro binary build..."
  echo "=================================="
  echo
  oc start-build -n ${OSE_NEXUS_PROJECT} nexus-pro --follow

fi

sleep 10

# Go back to CI project
oc project ${OSE_NEXUS_PROJECT}

echo
echo "=================================="
echo "Setup Complete!"
echo "=================================="
