FROM alpine:latest

ARG img_ver
ARG build_date=$(date +%Y-%m-%d)
# Forked from MarkusMcNugen/docker-openconnect ← TommyLau/docker-ocserv
LABEL org.opencontainers.image.authors="Ronnie McGrog" \
      org.opencontainers.image.url="https://github.com/mcgr0g/docker-openconnect-2nas" \
      org.opencontainers.image.documentation="https://github.com/mcgr0g/docker-openconnect-2nas/blob/master/README.md" \
      org.opencontainers.image.source="https://github.com/mcgr0g/docker-openconnect-2nas/blob/master/Dockerfile" \
      org.opencontainers.image.title="openconnect-2nas" \
      org.opencontainers.image.description="oscerv for home lab" \
      org.opencontainers.image.version="${img_ver}" \
      org.opencontainers.image.created="${build_date}"

VOLUME /config

# build stage
RUN buildDeps=" \
		curl \
		g++ \
		gawk \
		geoip \
		gnutls-dev \
		gpgme \
		krb5-dev \
		libc-dev \
		libev-dev \
		libnl3-dev \
		libproxy \
		libseccomp-dev \
		libtasn1 \
		linux-headers \
		linux-pam-dev \
		lz4-dev \
		make \
		oath-toolkit-liboath \
		oath-toolkit-libpskc \
		p11-kit \
		pcsc-lite-libs \
		protobuf-c \
		readline-dev \
		scanelf \
		stoken-dev \
		tar \
		tpm2-tss-esys \
		xz \
	"; \
	set -x \
	&& apk add --update --virtual .build-deps $buildDeps \
	&& export OC_VERSION=$(\
        curl --silent "https://ocserv.gitlab.io/www/download.html" 2>&1 \
            | grep -m 2 'The latest version of ocserv is'\
            | awk '/The latest version/ {print $NF}'\
        ) \
	&& curl -SL "https://www.infradead.org/ocserv/download/ocserv-$OC_VERSION.tar.xz" -o ocserv.tar.xz \
	&& mkdir -p /usr/src/ocserv \
	&& tar -xf ocserv.tar.xz -C /usr/src/ocserv --strip-components=1 \
	&& rm ocserv.tar.xz* \
	&& cd /usr/src/ocserv \
	&& ./configure \
	&& make \
	&& make install \
	&& cd / \
	&& rm -rf /usr/src/ocserv \
    && apk del .build-deps

# runner stage
RUN  runDeps="$( \
			scanelf --needed --nobanner /usr/local/sbin/ocserv \
				| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
				| xargs -r apk info --installed \
				| sort -u \
			)" \
    # gnutls krb5-libs libev libtasn1 linux-pam musl nettle
	&& apk add $runDeps \
        gnutls-utils \
        iptables \
        ipcalc \
        sipcalc \
        ca-certificates \
        bash \
        rsync \
        rsyslog \
        logrotate \
        runit \
	&& rm -rf /var/cache/apk/* \
    && update-ca-certificates

ADD ocserv /etc/default/ocserv

WORKDIR /config

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 4443
EXPOSE 4443/udp
CMD ["ocserv", "-c", "/config/ocserv.conf", "-f"]
