FROM quay.io/ukhomeofficedigital/centos-base:latest

ENV CLAM_VERSION=0.99.2

RUN yum install -y gcc openssl-devel wget make && \
    wget https://www.clamav.net/downloads/production/clamav-${CLAM_VERSION}.tar.gz && \
    tar xvzf clamav-${CLAM_VERSION}.tar.gz && \
    cd clamav-${CLAM_VERSION} && \
    ./configure && \
    make && make install && \
    yum remove -y gcc make wget && \
    yum update -y && yum clean all

RUN mkdir /usr/local/share/clamav
RUN mkdir /var/run/clamav && \
    chmod 750 /var/run/clamav

# Configure Clam AV...
ADD ./*.conf /usr/local/etc/
ADD ./helper.sh /
ADD ./readyness.sh /

VOLUME /var/lib/clamav

COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 3310

CMD ["clamd"]
