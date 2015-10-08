FROM quay.io/ukhomeofficedigital/centos-base

RUN yum install -y epel-release && \
    yum install -y \
        clamav-server \
        clamav-data \
        clamav-update \
        clamav-filesystem \
        clamav \
        clamav-lib \
    yum clean all

RUN mkdir /var/run/clamav && \
    chmod 750 /var/run/clamav

# Configure Clam AV...
ADD ./*.conf /etc/
ADD ./helper.sh /
ADD ./readyness.sh /

VOLUME /var/lib/clamav

COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 3310

CMD ["clamd"]