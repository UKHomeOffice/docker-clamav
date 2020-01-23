FROM openjdk:15-alpine as builder
COPY . .
RUN apk add maven && mvn install -DskipTests
RUN find / | grep clamav-rest-.*.jar

FROM openjdk:15-alpine

RUN apk -U upgrade && apk -U add curl

# Add clamav user
RUN addgroup -S clamav \
    && adduser -S -g clamav -u 1000 clamav -h /var/clamav-rest \
    && mkdir -p /var/clamav-rest

# Get the JAR file
COPY --from=builder /target/clamav-rest-1.0.2.jar /var/clamav-rest/clamav-rest-1.0.2.jar
COPY healthcheck.sh /var/clamav-rest/healthcheck.sh
COPY bootstrap.sh /var/clamav-rest/bootstrap.sh

RUN chown -R clamav:clamav /var/clamav-rest

USER 1000

# Open up the server
EXPOSE 8080

ENTRYPOINT ["/var/clamav-rest/bootstrap.sh"]
