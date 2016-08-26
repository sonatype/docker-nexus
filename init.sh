#!/bin/bash

set -e

SCRIPT_BASE_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Login Information
OSE_CLI_USER="admin"
OSE_CLI_PASSWORD="admin"
OSE_CI_PROJECT="ci"

# Login to OSE
echo
echo "Logging into OSE..."
echo
oc login -u ${OSE_CLI_USER} -p ${OSE_CLI_PASSWORD} >/dev/null 2>&1

# Create CI Project
echo
echo "Creating new CI Project (${OSE_CI_PROJECT})..."
echo
oc new-project ${OSE_CI_PROJECT} >/dev/null 2>&1

echo
echo "Configuring project permissions..."
echo

# Grant Default CI Account Edit Access to All Projects and OpenShift Project
oc policy add-role-to-user edit system:serviceaccount:${OSE_CI_PROJECT}:default -n ${OSE_CI_PROJECT}

# Process Nexus Template
echo
echo "Processing Nexus OSS Template..."
echo
oc create -f "${SCRIPT_BASE_DIR}/nexus-oss.json" -n ${OSE_CI_PROJECT} >/dev/null 2>&1

sleep 10

# Process Nexus Template
echo
echo "Processing Nexus Pro Template..."
echo
oc create -f "${SCRIPT_BASE_DIR}/nexus-pro.json" -n ${OSE_CI_PROJECT} >/dev/null 2>&1

sleep 10

echo
echo "Starting Nexus OSS binary build..."
echo
oc start-build -n ${OSE_CI_PROJECT} nexus-oss --follow >/dev/null 2>&1

sleep 10

echo
echo "Starting Nexus Pro binary build..."
echo
oc start-build -n ${OSE_CI_PROJECT} nexus-pro --follow >/dev/null 2>&1

# Go back to CI project
oc project ${OSE_CI_PROJECT} >/dev/null 2>&1

echo
echo "=================================="
echo "Setup Complete!"
echo "=================================="
