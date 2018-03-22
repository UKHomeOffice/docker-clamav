FROM quay.io/ukhomeofficedigital/centos-base

ENV CLAM_VERSION=0.99.3

RUN yum update -y && \
    yum install -y gcc openssl-devel wget make

RUN wget https://www.clamav.net/downloads/production/clamav-${CLAM_VERSION}.tar.gz && \
    tar xvzf clamav-${CLAM_VERSION}.tar.gz && \
    cd clamav-${CLAM_VERSION} && \
    ./configure && \
    make && make install && \
    yum remove -y gcc make && \
    yum clean all

# Add clamav user
RUN groupadd -r clamav && \
    useradd -r -g clamav clamav -d /var/lib/clamav && \
    mkdir -p /var/lib/clamav && \
    mkdir /usr/local/share/clamav && \
    chown -R clamav:clamav /var/lib/clamav /usr/local/share/clamav

# initial update of av databases
RUN wget -t 5 -T 99999 -O /var/lib/clamav/main.cvd http://database.clamav.net/main.cvd && \
    wget -t 5 -T 99999 -O /var/lib/clamav/daily.cvd http://database.clamav.net/daily.cvd && \
    wget -t 5 -T 99999 -O /var/lib/clamav/bytecode.cvd http://database.clamav.net/bytecode.cvd && \
    chown clamav:clamav /var/lib/clamav/*.cvd

# Configure Clam AV...
ADD ./*.conf /usr/local/etc/
ADD eicar.com /
ADD ./readyness.sh /

# permissions
RUN mkdir /var/run/clamav && \
    chown clamav:clamav /var/run/clamav && \
    chmod 750 /var/run/clamav && \
    chown -R clamav:clamav /usr/local/etc

USER clamav

VOLUME /var/lib/clamav

COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 3310
