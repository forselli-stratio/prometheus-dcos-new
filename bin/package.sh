#!/bin/bash -e
BASEDIR=$( cd "$(dirname "$0")" ; pwd -P )/..

cd $BASEDIR

if [[ -z "$1" ]]; then
	VERSION=$(cat $BASEDIR/VERSION)
else
	VERSION=$1
fi

source $BASEDIR/third-party-versions

# Prepare Dockerfile
sed -i "s/ARG PROMETHEUS_VERSION=.*/ARG PROMETHEUS_VERSION=$PROMETHEUS_VERSION/" Dockerfile
sed -i "s/ARG CONFD_VERSION=.*/ARG CONFD_VERSION=$CONFD_VERSION/" Dockerfile
sed -i "s/ARG SEC_UTILS_VERSION=.*/ARG SEC_UTILS_VERSION=$SEC_UTILS_VERSION/" Dockerfile
sed -i "s/ARG ALERTMANAGER_VERSION=.*/ARG ALERTMANAGER_VERSION=$ALERTMANAGER_VERSION/" Dockerfile

export GOROOT=$BASEDIR/go

export GOPATH=$BASEDIR

wget -q http://tools.stratio.com/go/go1.9.7.linux-amd64.tar.gz

tar -xvzf go1.9.7.linux-amd64.tar.gz 

cd $GOPATH/src/service_discovery

$GOROOT/bin/go build --ldflags '-linkmode external -extldflags "-static"' -o $BASEDIR/service_discovery .