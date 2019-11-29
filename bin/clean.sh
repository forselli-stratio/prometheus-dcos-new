#!/bin/bash -e

BASEDIR=$( cd "$(dirname "$0")" ; pwd -P )/..

cd "$BASEDIR"

rm -rf go go1.9.7.linux-amd64.tar.gz

# Clean Dockerfile
sed -i "s/ARG PROMETHEUS_VERSION=.*/ARG PROMETHEUS_VERSION=to-be-automatically-changed-in-package/" Dockerfile
sed -i "s/ARG CONFD_VERSION=.*/ARG CONFD_VERSION=to-be-automatically-changed-in-package/" Dockerfile
sed -i "s/ARG SEC_UTILS_VERSION=.*/ARG SEC_UTILS_VERSION=to-be-automatically-changed-in-package/" Dockerfile
sed -i "s/ARG ALERTMANAGER_VERSION=.*/ARG ALERTMANAGER_VERSION=to-be-automatically-changed-in-package/" Dockerfile
