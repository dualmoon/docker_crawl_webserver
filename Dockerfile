FROM debian:jessie
MAINTAINER IgorSh

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r -g 1000 crawluser && useradd -r -g crawluser -u 1000 crawluser

RUN apt-get update \
    && apt-get upgrade -y
RUN apt-get install -y \
    wget \
    git \
    build-essential \
    libncursesw5-dev \
    bison \
    flex \
    liblua5.1-0-dev \
    libsqlite3-dev \
    libz-dev \
    pkg-config \
    libsdl2-image-dev \
    libsdl2-mixer-dev \
    libsdl2-dev \
    libfreetype6-dev \
    libpng-dev \
    ttf-dejavu-core \
        && rm -rf /var/lib/apt/lists/*

# add gosu for easy step-down from root
ENV GOSU_VERSION 1.7
RUN set -x \
        && apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/* \
        && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
        && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
        && export GNUPGHOME="$(mktemp -d)" \
        && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
        && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
        && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
        && chmod +x /usr/local/bin/gosu \
        && gosu nobody true \
        && apt-get purge -y --auto-remove ca-certificates wget

RUN git clone https://github.com/crawl/crawl.git \
        && cd /crawle \
        && git submodule update --init \
        && chown -R crawluser:crawluser /crawl \
        && cd /crawle/crawl-ref/source \
        && make TILES=y

WORKDIR /crawle/crawl-ref/source

VOLUME /crawle

EXPOSE 8080

COPY docker-entrypoint.sh /entrypoint.sh
RUN chown -R crawluser:crawluser /entrypoint.sh && chmod 777 /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

#USER builduser
CMD ["python webserver/server.py"]
