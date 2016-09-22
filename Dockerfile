FROM quay.io/ukhomeofficedigital/centos-base

ENV CLAM_VERSION=0.99.2
RUN yum install -y gcc openssl-devel wget make

RUN wget https://www.clamav.net/downloads/production/clamav-${CLAM_VERSION}.tar.gz && \
    tar xvzf clamav-${CLAM_VERSION}.tar.gz && \
    cd clamav-${CLAM_VERSION} && \
    ./configure && \
    make && make install

RUN  mkdir /usr/local/share/clamav && mkdir /var/lib/clamav


RUN wget -O /var/lib/clamav/main.cvd http://database.clamav.net/main.cvd && \
    wget -O /var/lib/clamav/daily.cvd http://database.clamav.net/daily.cvd && \
    wget -O /var/lib/clamav/bytecode.cvd http://database.clamav.net/bytecode.cvd
    
RUN yum remove -y gcc make wget #cleanup
RUN yum update -y && yum clean all
RUN mkdir /var/run/clamav && \
    chmod 750 /var/run/clamav

# Configure Clam AV...
ADD ./*.conf /usr/local/etc/
ADD eicar.com /
ADD ./readyness.sh /

VOLUME /var/lib/clamav

COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 3310
