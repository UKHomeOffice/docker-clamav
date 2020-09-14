FROM alpine:3.11 as base

ENV CLAM_VERSION=0.102.1-r0

#RUN apk add --no-cache clamav=$CLAM_VERSION clamav-libunrar=$CLAM_VERSION
### specified env version causes breakages in alpine. 
# Add clamav user
# sort out permissions
RUN set -eux; \
    apk update; \
    apk add --no-cache \
    clamav \
    clamav-libunrar ;\
    rm -rf /var/cache/apk/* ; \
    adduser -S -G clamav -u 1000 clamav_user -h /var/lib/clamav ; \
    mkdir -p /var/lib/clamav ; \
    mkdir /usr/local/share/clamav ; \
    chown -R clamav_user:clamav /var/lib/clamav /usr/local/share/clamav /etc/clamav ;\
    mkdir /var/run/clamav ; \
    chown clamav_user:clamav /var/run/clamav ; \
    chmod 750 /var/run/clamav

from base as build
# Configure Clam AV...
COPY --chown=clamav_user:clamav ./*.conf /etc/clamav/
COPY --chown=clamav_user:clamav eicar.com readyness.sh docker-entrypoint.sh  /
#COPY --chown=clamav_user:clamav ["eicar.com", "readyness.sh", "docker-entrypoint.sh",  "/"]
USER 1000
# initial update of av databases
RUN freshclam


from build as clamav
VOLUME /var/lib/clamav
ENTRYPOINT ["/docker-entrypoint.sh"]
EXPOSE 3310
