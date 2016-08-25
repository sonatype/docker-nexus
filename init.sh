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

# CI Project

# Process RHEL Template
echo
echo "Waiting for RHEL ImageStream Template..."
echo
oc create -n ${OSE_CI_PROJECT} -f"${SCRIPT_BASE_DIR}/support/templates/rhel7-is.json" >/dev/null 2>&1

# Import Upstream Image
echo
echo "Importing RHEL7 ImageStream..."
echo
oc import-image -n ${OSE_CI_PROJECT} rhel7 >/dev/null 2>&1

# Process Nexus Template
echo
echo "Processing Nexus Template..."
echo
oc process -v APPLICATION_NAME=nexus -f "${SCRIPT_BASE_DIR}/support/templates/nexus-persistent-template.json" | oc -n ${OSE_CI_PROJECT} create -f - >/dev/null 2>&1

sleep 5

echo
echo "Starting Nexus Pro binary build..."
echo
oc start-build -n ${OSE_CI_PROJECT} nexus --from-dir="${SCRIPT_BASE_DIR}/pro" --follow >/dev/null 2>&1

# Go back to CI project
oc project ${OSE_CI_PROJECT} >/dev/null 2>&1

echo
echo "=================================="
echo "Setup Complete!"
echo "=================================="
