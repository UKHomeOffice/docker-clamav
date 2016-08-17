FROM quay.io/ukhomeofficedigital/centos-base:latest

MAINTAINER lokori <antti.virtanen@iki.fi>

RUN yum update -y 
RUN yum install -y java-1.8.0-openjdk
RUN yum clean all

# Set environment variables.
ENV HOME /root
ADD . /build/
WORKDIR /build/
RUN /build/maven-build.sh

# Get the JAR file

# Define working directory.
WORKDIR /var/clamav-rest/

# Open up the server 
EXPOSE 8080

ADD bootstrap.sh /
ENTRYPOINT ["/bootstrap.sh"]
