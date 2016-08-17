#!/usr/bin/env bash

set -e

yum install -y java-1.8.0-openjdk-devel
export MAVEN_VERSION=3.3.9
export JAVA_HOME=/usr/lib/jvm/jre-openjdk

mkdir -p /usr/share/maven
curl -fsSL http://apache.osuosl.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz \
    | tar -xzC /usr/share/maven --strip-components=1

ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

export MAVEN_HOME=/usr/share/maven

mvn install
mkdir /var/clamav-rest
mv target/clamav-rest-1.0.0.jar /var/clamav-rest/
rm -fr /usr/share/maven
yum remove -y java-1.8.0-openjdk-devel