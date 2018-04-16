FROM quay.io/ukhomeofficedigital/openjdk8:latest

RUN yum update -y && \
    yum clean all

# Add clamav user
RUN groupadd -r clamav && \
    useradd -r -g clamav -u 1000 clamav -d /var/clamav-rest/&& \
    mkdir -p /var/clamav-rest/ && \
    chown -R clamav:clamav /var/clamav-rest/

USER 1000

# Get the JAR file
COPY target/clamav-rest-1.0.2.jar /var/clamav-rest/
COPY healthcheck.sh /var/clamav-rest/healthcheck.sh
COPY bootstrap.sh /var/clamav-rest/bootstrap.sh

# Open up the server
EXPOSE 8080

ENTRYPOINT ["/var/clamav-rest/bootstrap.sh"]
