FROM quay.io/ukhomeofficedigital/centos-base

RUN yum install -y epel-release && \
    yum install -y \
        clamav-server \
        clamav-data \
        clamav-update \
        clamav-filesystem \
        clamav \
        clamav-lib \
        clamav-devel && \
    cp /usr/share/clamav/template/clamd.conf /etc/clamd.conf && \
    yum remove -y clamav-devel && \
    yum clean all

RUN mkdir /var/run/clamav && \
    chmod 750 /var/run/clamav

RUN sed -i '/^Example/d' /etc/clamd.conf && \
    sed -i 's/^#*Foreground .*$/Foreground yes/g' /etc/clamd.conf && \
    sed -i '/^User <USER>/d' /etc/clamd.conf && \
    echo "TCPSocket 3310" >> /etc/clamd.conf && \
    sed -i 's/^Foreground .*$/Foreground true/g' /etc/freshclam.conf && \
    sed -i '/^Example/d' /etc/freshclam.conf

VOLUME /var/lib/clamav

COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 3310

CMD ["clamd"]