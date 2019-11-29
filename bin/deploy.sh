#!/bin/bash -e

DIR=dist
BASEDIR=`dirname $0`/..

if [[ -z "$1" ]]; then
	VERSION=$(cat $BASEDIR/VERSION)
else
	VERSION=$1
fi

cd $BASEDIR
mkdir -p $DIR

docker -H tcp://jenkins.stratio.com:12375 pull qa.stratio.com/stratio/prometheus-dcos:$VERSION
docker -H tcp://jenkins.stratio.com:12375 tag qa.stratio.com/stratio/prometheus-dcos:$VERSION stratio/prometheus-dcos:$VERSION
docker -H tcp://jenkins.stratio.com:12375 save -o dist/stratio-prometheus-dcos-${VERSION}.tar.gz stratio/prometheus-dcos:$VERSION
docker -H tcp://jenkins.stratio.com:12375 rmi qa.stratio.com/stratio/prometheus-dcos:$VERSION
docker -H tcp://jenkins.stratio.com:12375 rmi stratio/prometheus-dcos:$VERSION

if [ -d "$DIR" ]; then
	echo "Uploading to Nexus..."
	curl -u stratio:${NEXUSPASS} --upload-file dist/stratio-prometheus-dcos-${VERSION}.tar.gz http://niquel.stratio.com/repository/paas/ansible/
else
	echo "Run 'make deploy' again"
	exit 1
fi
