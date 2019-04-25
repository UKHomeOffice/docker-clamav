FROM quay.io/ukhomeofficedigital/centos-base:latest

ENV CLAM_VERSION=0.101.2

RUN yum update -y -q && \
    yum install -y -q gcc-c++ openssl-devel wget make

COPY talos.pub /tmp/talos.pub

RUN wget -nv https://www.clamav.net/downloads/production/clamav-${CLAM_VERSION}.tar.gz && \
    wget -nv https://www.clamav.net/downloads/production/clamav-${CLAM_VERSION}.tar.gz.sig &&  \
    gpg --import /tmp/talos.pub && \
    gpg --decrypt clamav-${CLAM_VERSION}.tar.gz.sig && \
    tar xzf clamav-${CLAM_VERSION}.tar.gz && \
    cd clamav-${CLAM_VERSION} && \
    ./configure && \
    make && make install && \
    rm -rf /clamav-${CLAM_VERSION} && \
    rm -rf /tmp/talos.pub && \
    yum remove -y -q make gcc-c++ openssl-devel && \
    yum clean all

# Add clamav user
RUN groupadd -r clamav && \
    useradd -r -g clamav -u 1000 clamav -d /var/lib/clamav && \
    mkdir -p /var/lib/clamav && \
    mkdir /usr/local/share/clamav && \
    chown -R clamav:clamav /var/lib/clamav /usr/local/share/clamav

# Configure Clam AV...
RUN chown clamav:clamav -R /usr/local/etc/
COPY --chown=clamav:clamav ./*.conf /usr/local/etc/
COPY --chown=clamav:clamav eicar.com /
COPY --chown=clamav:clamav ./readyness.sh /

# initial update of av databases
RUN freshclam && \
    chown clamav:clamav /var/lib/clamav/*.cvd
    
# permissions
RUN mkdir /var/run/clamav && \
    chown clamav:clamav /var/run/clamav && \
    chmod 750 /var/run/clamav

USER 1000

VOLUME /var/lib/clamav

COPY --chown=clamav:clamav docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 3310
